//
//  AudioEngineState.swift
//  iES
//
//  Created by Никита Пивоваров on 10.01.2025.
//


import AVFoundation
import os

enum AudioEngineState { case stopped, started, paused, playing }

protocol AudioEngineProtocol: AnyObject {
    func schedule(buffer aBuffer: [Float32], withSampleRate sampleRate: SampleRate)
}

final class AudioEngine: AudioEngineProtocol {
    private let queue: DispatchQueue = DispatchQueue(label: "AudioEngineQueue", qos: .userInteractive)
    private let engine: AVAudioEngine = AVAudioEngine.init()
    private let playerNode: AVAudioPlayerNode = AVAudioPlayerNode.init()
    private var engineState: AudioEngineState = .stopped
    private var currentAudioFormat: AVAudioFormat?
    private var lastSampleRate: SampleRate?
    
    // MARK: - Life Cycle
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption(_:)), name: AVAudioSession.interruptionNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - AudioEngineProtocol
    
    func schedule(buffer aBuffer: [Float32], withSampleRate sampleRate: SampleRate) {
        self.queue.async { [weak self] in
            
            if let safeLastSampleRate = self?.lastSampleRate,
                safeLastSampleRate != sampleRate {
                self?.engine.stop()
            }
            
            switch self?.engineState ?? .stopped {
            case .stopped, .paused:
                do {
                    try self?.startEngine(withSampleRate: sampleRate)
                } catch {
                    return
                }
                fallthrough
            case .playing, .started:
                guard let format: AVAudioFormat = AVAudioFormat.init(standardFormatWithSampleRate: sampleRate.doubleValue, channels: 1),
                    let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: sampleRate.bufferCapacity)
                    else { return }
                    
                buffer.frameLength = buffer.frameCapacity
                let channels = UnsafeBufferPointer(start: buffer.floatChannelData, count: Int(buffer.format.channelCount))
                let _ = aBuffer.withUnsafeBytes { ptr in
                    memcpy(UnsafeMutableRawPointer(channels[0]), ptr.baseAddress, MemoryLayout<Float32>.size * aBuffer.count)
                    self?.playerNode.scheduleBuffer(buffer, completionHandler: nil)
                    self?.play()
                }
            }
        }
    }
    
    // MARK: - Notifications
    
    @objc private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }
        
        switch type {
        case .began:
            self.queue.async { [weak self] in
                self?.stop()
            }
        case .ended:
            self.queue.async { [weak self] in
                self?.stop()
            }
        @unknown default:
            break
        }
    }
    
    // MARK: - Private Functions
    
    private func play() {
        switch self.engineState {
        case .started:
            self.setPlaybackCategory()
            self.playerNode.play(at: nil)
            self.engineState = .playing
        default:
            break
        }
    }
    
    private func stop() {
        switch self.engineState {
        case .started, .playing, .paused:
            self.playerNode.stop()
            self.engine.stop()
            self.engine.reset()
            for p in self.engine.attachedNodes.compactMap({ $0 as? AVAudioPlayerNode }) { self.engine.detach(p) }
            self.engineState = .stopped
            self.setAudioSessionInactive()
        default:
            break
        }
    }
        
    private func audioFormat(forSampleRate sampleRate: SampleRate) throws -> AVAudioFormat {
        if let safeAudioFormat = AVAudioFormat.init(standardFormatWithSampleRate: sampleRate.doubleValue, channels: 1),
            let _ = AVAudioPCMBuffer(pcmFormat: safeAudioFormat, frameCapacity: sampleRate.bufferCapacity)
        {
            self.currentAudioFormat = safeAudioFormat
            return safeAudioFormat
        } else if let fallbackAudioFormat = AVAudioFormat.init(standardFormatWithSampleRate: 44100, channels: 1),
            let _ = AVAudioPCMBuffer(pcmFormat: fallbackAudioFormat, frameCapacity: sampleRate.bufferCapacity) {
            self.currentAudioFormat = fallbackAudioFormat
            return fallbackAudioFormat
        } else {
            throw NSError(domain: "", code: 1000, userInfo: nil)
        }
    }
    
    private func startEngine(withSampleRate sampleRate: SampleRate) throws {
        let audioFormat: AVAudioFormat
        do {
            audioFormat = try self.audioFormat(forSampleRate: sampleRate)
        } catch {
            throw error
        }
        
        do {
            try self.startEngine(withAudioFormat: audioFormat)
        } catch {
            throw error
        }
    }
    
    private func startEngine(withAudioFormat aAudioFormat: AVAudioFormat) throws{
        switch self.engineState {
        case .stopped:
            self.attachNodesToEngineIfNeeded(withAudioFormat: aAudioFormat)
            do {
                try self.engine.start()
            }
            catch {
                throw error
            }
            
            if self.engineState == .stopped {
                self.engineState = .started
            }
        case .paused:
            do {
                try self.engine.start()
            } catch {
                throw error
            }
        default: break
        }
    }
    
    private func attachNodesToEngineIfNeeded(withAudioFormat audioFormat: AVAudioFormat) {
        guard self.engine.attachedNodes.compactMap({ $0 as? AVAudioPlayerNode }).isEmpty else { return }
        self.engine.attach(self.playerNode)
        self.engine.connect(self.playerNode, to: self.engine.outputNode, format: audioFormat)
    }
    
    private func setPlaybackCategory() {
        do { try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, policy: .longFormAudio, options: []) }
        catch { os_log(OSLogType.error, "Failed to set audio session playback category: %@", error.localizedDescription) }
       
        do { try AVAudioSession.sharedInstance().setActive(true, options: []) }
        catch { os_log(OSLogType.error, "Failed to set audio session active: %@", error.localizedDescription) }
    }
   
    private func setAudioSessionInactive() {
        let notifyOthers: Bool = UserDefaults.standard.bool(forKey: Settings.Keys.audioSessionNotifyOthersOnDeactivation)
       
        do { try AVAudioSession.sharedInstance().setActive(false, options: notifyOthers ? .notifyOthersOnDeactivation : []) }
        catch { os_log(OSLogType.error, "Failed to set audio session inactive: %@", error.localizedDescription) }
    }
}
