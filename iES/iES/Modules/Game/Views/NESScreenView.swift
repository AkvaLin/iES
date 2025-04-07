//
//  NESScreenView.swift
//  iES
//
//  Created by Никита Пивоваров on 10.01.2025.
//

import UIKit
import MetalKit
#if !targetEnvironment(simulator)
import MetalFX
#endif
import os

typealias NESScreenView = MTKView & MTKViewDelegate & MTKViewBuffered

protocol MTKViewBuffered {
    var buffer: [UInt32] { get set }
    var stopUpdating: Bool { get set }
}

#if !targetEnvironment(simulator)
final class NESScreenViewMetalFX: NESScreenView {
    private let queue = DispatchQueue(label: "renderQueue", qos: .userInteractive)
    private var hasSuspended = false
    private let commandQueue: MTLCommandQueue
    private var nearestNeighborRendering: Bool
    private var integerScaling: Bool
    private var checkForRedundantFrames: Bool
    private var scanlines: Scanlines
    private var lastDrawableSize: CGSize = .zero
    private var scanlineBuffer: [UInt32]
    private var pipelineState: MTLRenderPipelineState!
    private var vertexBuffer: MTLBuffer!
    private var nesTexture: MTLTexture!
    private var spatialScaler: MTLFXSpatialScaler?
    var stopUpdating: Bool = false
    
    required init(frame: CGRect) {
        let dev = MTLCreateSystemDefaultDevice()!
        self.commandQueue = dev.makeCommandQueue()!
        self.nearestNeighborRendering = UserDefaults.standard.bool(forKey: Settings.Keys.nearestNeighborRendering)
        self.checkForRedundantFrames = UserDefaults.standard.bool(forKey: Settings.Keys.checkForRedundantFrames)
        self.integerScaling = UserDefaults.standard.bool(forKey: Settings.Keys.integerScaling)
        self.scanlines = Scanlines(rawValue: UInt8(UserDefaults.standard.integer(forKey: Settings.Keys.scanlines))) ?? Settings.DefaultValues.defaultScanlines
        self.scanlineBuffer = self.scanlines.colorArray()
        
        super.init(frame: frame, device: dev)
        self.device = dev
        self.autoResizeDrawable = true
        self.drawableSize = CGSize(width: PPU.screenWidth, height: PPU.screenHeight)
        self.isPaused = true
        self.enableSetNeedsDisplay = false
        self.framebufferOnly = false
        self.delegate = self
        self.isOpaque = false
        self.colorPixelFormat = .bgra8Unorm
        
        setupMetal()
        createTexture()
        setupVertices()
        setupMetalFX()
        
        NotificationCenter.default.addObserver(self, selector: #selector(appResignedActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appBecameActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    deinit { NotificationCenter.default.removeObserver(self) }
    
    var buffer: [UInt32] = PPU.emptyBuffer {
        didSet {
            guard !self.checkForRedundantFrames || self.drawableSize != self.lastDrawableSize || !self.buffer.elementsEqual(oldValue) else { return }
            self.queue.async { [weak self] in self?.draw() }
        }
    }
    
    private func setupMetal() {
        let library = device?.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vertex_main")
        let fragmentFunction = library?.makeFunction(name: "fragment_main")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        do {
            pipelineState = try device?.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Failed to create pipeline state: \(error)")
        }
    }
    
    private func createTexture() {
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.textureType = .type2D
        textureDescriptor.width = PPU.screenWidth
        textureDescriptor.height = PPU.screenHeight
        textureDescriptor.pixelFormat = .bgra8Unorm
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        
        nesTexture = device?.makeTexture(descriptor: textureDescriptor)
        assert(nesTexture != nil, "Failed to create NES texture")
    }
    
    
    private func setupVertices() {
        let quadVertices: [Float] = [
            -1.0, -1.0,  0.0, 1.0,
             1.0, -1.0,  1.0, 1.0,
             -1.0,  1.0,  0.0, 0.0,
             1.0,  1.0,  1.0, 0.0
        ]
        vertexBuffer = device?.makeBuffer(bytes: quadVertices, length: quadVertices.count * MemoryLayout<Float>.size, options: [])
    }
    
    private func setupMetalFX() {
        
        guard let device else { return }
        
        let fxScaler = MTLFXSpatialScalerDescriptor()
        
        fxScaler.inputWidth = PPU.screenWidth
        fxScaler.inputHeight = PPU.screenHeight
        fxScaler.outputWidth = Int(self.drawableSize.width)
        fxScaler.outputHeight = Int(self.drawableSize.height)
        fxScaler.colorTextureFormat = .bgra8Unorm
        fxScaler.outputTextureFormat = .bgra8Unorm
        fxScaler.colorProcessingMode = .perceptual
        
        spatialScaler = fxScaler.makeSpatialScaler(device: device)
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        setupMetalFX()
    }
    
    func draw(in view: MTKView) {
        guard let safeCurrentDrawable = self.currentDrawable,
              let safeCommandBuffer = self.commandQueue.makeCommandBuffer(),
              let spatialScaler,
              let device = self.device else {
            return
        }
        if !stopUpdating {
            setupMetalFX()
        }
        
        let nativeWidth = PPU.screenWidth
        let nativeHeight = PPU.screenHeight
        
        let nesTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: nativeWidth,
            height: nativeHeight,
            mipmapped: false
        )
        nesTextureDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
        nesTextureDescriptor.storageMode = .shared  // 📌 Важно: .shared, т.к. мы пишем в неё CPU
        guard let nesTexture = device.makeTexture(descriptor: nesTextureDescriptor) else {
            fatalError("❌ Failed to create NES texture")
        }
        
        nesTexture.replace(region: MTLRegionMake2D(0, 0, nativeWidth, nativeHeight),
                           mipmapLevel: 0,
                           withBytes: buffer,
                           bytesPerRow: nativeWidth * 4)
        
        let upscaleWidth = spatialScaler.outputWidth
        let upscaleHeight = spatialScaler.outputHeight
        
        let upscaleTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: upscaleWidth,
            height: upscaleHeight,
            mipmapped: false
        )
        upscaleTextureDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
        upscaleTextureDescriptor.storageMode = .private
        guard let upscaleTexture = device.makeTexture(descriptor: upscaleTextureDescriptor) else {
            fatalError("❌ Failed to create upscale texture")
        }
        
        spatialScaler.colorTexture = nesTexture
        spatialScaler.outputTexture = upscaleTexture
        
        assert(spatialScaler.colorTexture != nil, "❌ spatialScaler.colorTexture is nil!")
        assert(spatialScaler.outputTexture != nil, "❌ spatialScaler.outputTexture is nil!")
        
        spatialScaler.encode(commandBuffer: safeCommandBuffer)
        
        if let blitEncoder = safeCommandBuffer.makeBlitCommandEncoder() {
            blitEncoder.copy(from: upscaleTexture,
                             sourceSlice: 0,
                             sourceLevel: 0,
                             sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                             sourceSize: MTLSize(width: upscaleTexture.width,
                                                 height: upscaleTexture.height,
                                                 depth: 1),
                             to: safeCurrentDrawable.texture,
                             destinationSlice: 0,
                             destinationLevel: 0,
                             destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
            blitEncoder.endEncoding()
        }
        
        safeCommandBuffer.present(safeCurrentDrawable)
        safeCommandBuffer.commit()
    }
    
    @objc private func appResignedActive() {
        queue.suspend()
        hasSuspended = true
    }
    @objc private func appBecameActive() {
        if hasSuspended {
            queue.resume()
            hasSuspended = false
        }
    }
}
#endif

final class NESScreenViewTraditional: NESScreenView {
    private let queue: DispatchQueue = DispatchQueue.init(label: "renderQueue", qos: .userInteractive)
    private var hasSuspended: Bool = false
    private let rgbColorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
    private let context: CIContext
    private let commandQueue: MTLCommandQueue
    private var nearestNeighborRendering: Bool
    private var integerScaling: Bool
    private var checkForRedundantFrames: Bool
    private var scanlines: Scanlines
    private var currentScale: CGFloat = 1.0
    private var viewportOffset: CGPoint = CGPoint.zero
    private var lastDrawableSize: CGSize = CGSize.zero
    private var scanlineBuffer: [UInt32]
    private var scanlineBaseImage: CIImage
    private var scanlineImage: CIImage = CIImage.empty()
    private var tNesScreen: CGAffineTransform = CGAffineTransform.identity
    static private let elementLength: Int = 4
    static private let bitsPerComponent: Int = 8
    static private let imageSize: CGSize = CGSize(width: PPU.screenWidth, height: PPU.screenHeight)
    var stopUpdating: Bool = false
    
    required init(frame: CGRect)
    {
        let dev: MTLDevice = MTLCreateSystemDefaultDevice()!
        let commandQueue = dev.makeCommandQueue()!
        let s: Scanlines = Scanlines(rawValue: UInt8(UserDefaults.standard.integer(forKey: Settings.Keys.scanlines))) ?? Settings.DefaultValues.defaultScanlines
        self.context = CIContext.init(mtlCommandQueue: commandQueue, options: [.cacheIntermediates: false])
        self.commandQueue = commandQueue
        self.nearestNeighborRendering = UserDefaults.standard.bool(forKey: Settings.Keys.nearestNeighborRendering)
        self.checkForRedundantFrames = UserDefaults.standard.bool(forKey: Settings.Keys.checkForRedundantFrames)
        self.integerScaling = UserDefaults.standard.bool(forKey: Settings.Keys.integerScaling)
        self.scanlines = s
        self.scanlineBuffer = s.colorArray()
        self.scanlineBaseImage = CIImage(bitmapData: NSData(bytes: &self.scanlineBuffer, length: PPU.screenHeight * 2 *  Self.elementLength) as Data, bytesPerRow: Self.elementLength, size: CGSize(width: 1, height: PPU.screenHeight * 2), format: CIFormat.ARGB8, colorSpace: self.rgbColorSpace)
        super.init(frame: frame, device: dev)
        self.device = dev
        self.autoResizeDrawable = true
        self.drawableSize = CGSize(width: PPU.screenWidth, height: PPU.screenHeight)
        self.isPaused = true
        self.enableSetNeedsDisplay = false
        self.framebufferOnly = false
        self.delegate = self
        self.isOpaque = false
        self.clearsContextBeforeDrawing = false
        NotificationCenter.default.addObserver(self, selector: #selector(appResignedActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appBecameActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    deinit { NotificationCenter.default.removeObserver(self) }
    
    var buffer: [UInt32] = PPU.emptyBuffer {
        didSet {
            guard !self.checkForRedundantFrames || self.drawableSize != self.lastDrawableSize || !self.buffer.elementsEqual(oldValue)
            else { return }
            
            self.queue.async { [weak self] in
                self?.draw()
            }
        }
    }
    
    // MARK: - MTKViewDelegate
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        let exactScale: CGFloat = size.width / CGFloat(PPU.screenWidth)
        self.currentScale = self.integerScaling ? floor(exactScale) : exactScale
        self.viewportOffset = self.integerScaling ? CGPoint(x: (size.width - (CGFloat(PPU.screenWidth) * self.currentScale)) * 0.5, y: (size.height - (CGFloat(PPU.screenHeight) * self.currentScale)) * 0.5) : CGPoint.zero
        
        let t1: CGAffineTransform = CGAffineTransform(scaleX: self.currentScale, y: self.currentScale)
        let t2: CGAffineTransform = self.integerScaling ? CGAffineTransform(translationX: self.viewportOffset.x, y: self.viewportOffset.y) : CGAffineTransform.identity
        self.tNesScreen = t1.concatenating(t2)
        
        switch self.scanlines {
        case .off: break
        default:
            let t1s: CGAffineTransform = CGAffineTransform(scaleX: self.currentScale * CGFloat(PPU.screenWidth), y: self.currentScale * 0.5)
            let t: CGAffineTransform = t1s.concatenating(t2)
            self.scanlineImage = self.scanlineBaseImage.samplingNearest().transformed(by: t)
        }
    }
    
    func draw(in view: MTKView) {
        guard let safeCurrentDrawable = self.currentDrawable,
              let safeCommandBuffer = self.commandQueue.makeCommandBuffer()
        else { return }
        
        let image: CIImage
        let baseImage: CIImage = CIImage(
            bitmapData: NSData(
                bytes: &self.buffer,
                length: PPU.screenWidth * PPU.screenHeight * Self.elementLength
            ) as Data,
            bytesPerRow: PPU.screenWidth * Self.elementLength,
            size: Self.imageSize,
            format: CIFormat.ARGB8,
            colorSpace: self.rgbColorSpace
        )
        
        if self.nearestNeighborRendering {
            image = self.scanlineImage.composited(over: baseImage.samplingNearest().transformed(by: self.tNesScreen))
        } else {
            image = self.scanlineImage.composited(over: baseImage.transformed(by: self.tNesScreen))
        }
        
        let renderDestination = CIRenderDestination(
            width: Int(self.drawableSize.width),
            height: Int(self.drawableSize.height),
            pixelFormat: self.colorPixelFormat,
            commandBuffer: safeCommandBuffer
        ) {
            () -> MTLTexture in return safeCurrentDrawable.texture
        }
        
        do {
            let _ = try self.context.startTask(toRender: image, to: renderDestination)
        } catch {
            os_log("%@", error.localizedDescription)
        }
        
        safeCommandBuffer.present(safeCurrentDrawable)
        safeCommandBuffer.commit()
        
        self.lastDrawableSize = self.drawableSize
    }
    
    @objc private func appResignedActive() {
        self.queue.suspend()
        self.hasSuspended = true
    }
    
    @objc private func appBecameActive() {
        if self.hasSuspended {
            self.queue.resume()
            self.hasSuspended = false
        }
    }
}
