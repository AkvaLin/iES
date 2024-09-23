//
//  PPU.swift
//  iES
//
//  Created by Никита Пивоваров on 22.09.2024.
//

/// NES Picture Processing Unit
struct PPU {
    private(set) var cycle: Int = 340
    private(set) var frame: UInt64 = 0
    
    /// #Important
    /// an optimization to prevent unnecessary Mapper object type lookups and mapper step calls during frequent PPU.step() calls
    private let mapperHasStep: Bool
    private let mapperHasExtendedNametableMapping: Bool
    
    var mapper: MapperProtocol
    private var paletteData: [UInt8] = [UInt8].init(repeating: 0, count: 32)
    private var nameTableData: [UInt8] = [UInt8].init(repeating: 0, count: 2048)
    private var oamData: [UInt8] = [UInt8].init(repeating: 0, count: 256)
    
    /// for each mirroring mode, return nametable offset sequence
    private static let nameTableOffsetSequence: [[UInt16]] = [
        [0, 0, 1024, 1024],
        [0, 1024, 0, 1024],
        [0, 0, 0, 0],
        [1024, 1024, 1024, 1024],
        [0, 1024, 2048, 3072]
    ]
    
    private static let nmiMaximumDelay: UInt8 = 16
    
    // MARK: PPU Registers
    
    /// current vram address (15 bit)
    private var v: UInt16 = 0
    
    /// temporary vram address (15 bit)
    private var t: UInt16 = 0
    
    /// fine x scroll (3 bit)
    private var x: UInt8 = 0
    
    /// write toggle bit
    private var w: Bool = false
    
    /// even / odd frame flag bit
    private var f: Bool = false
    
    private var register: UInt8 = 0
    
    // MARK: NMI flags
    private var nmiOccurred: Bool = false {
        didSet {
            guard self.nmiOccurred,
                  !oldValue,
                  self.nmiOutput
            else { return }
            
            // TODO: this fixes some games (e.g. Burger Time), but shouldn't be necessary - the timings are off somewhere
            self.nmiDelay = PPU.nmiMaximumDelay
        }
    }
    private var nmiOutput: Bool = false
    private var nmiDelay: UInt8 = 0
    
    // MARK: Background temporary variables
    private var nameTableByte: UInt8 = 0
    private var attributeTableByte: UInt8 = 0
    private var lowTileByte: UInt8 = 0
    private var highTileByte: UInt8 = 0
    private var tileData: UInt64 = 0
    
    // MARK: Sprite temporary variables
    private var spriteCount: Int = 0
    private var spritePatterns: [UInt32] = [UInt32].init(repeating: 0, count: 8)
    private var spritePositions: [UInt8] = [UInt8].init(repeating: 0, count: 8)
    private var spritePriorities: [UInt8] = [UInt8].init(repeating: 0, count: 8)
    private var spriteIndexes: [UInt8] = [UInt8].init(repeating: 0, count: 8)
    
    // MARK: $2000 PPUCTRL
    /// 0: $2000; 1: $2400; 2: $2800; 3: $2C00
    private var flagNameTable: UInt8 = 0
    
    /// 0: add 1; 1: add 32
    private var flagIncrement: Bool = false
    
    /// 0: $0000; 1: $1000; ignored in 8x16 mode
    private var flagSpriteTable: Bool = false
    
    /// 0: $0000; 1: $1000
    private var flagBackgroundTable: Bool = false
    
    /// 0: 8x8; 1: 8x16
    private var flagSpriteSize: Bool = false
    
    /// 0: read EXT; 1: write EXT
    private var flagMasterSlave: Bool = false
    
    // MARK: $2001 PPUMASK
    /// false: color; true: grayscale
    private var flagGrayscale: Bool = false
    
    /// false: hide; true: show
    private var flagShowLeftBackground: Bool = false
    
    /// false: hide; true: show
    private var flagShowLeftSprites: Bool = false
    
    /// false: hide; true: show
    private(set) var flagShowBackground: Bool = false
    
    /// false: hide; true: show
    private(set) var flagShowSprites: Bool = false
    
    /// false: normal; true: emphasized
    private var flagRedTint: Bool = false
    
    /// false: normal; true: emphasized
    private var flagGreenTint: Bool = false
    
    /// false: normal; true: emphasized
    private var flagBlueTint: Bool = false
    
    // MARK: $2002 PPUSTATUS
    private var flagSpriteZeroHit: UInt8 = 0
    private var flagSpriteOverflow: UInt8 = 0
    
    // $2003 OAMADDR
    private var oamAddress: UInt8 = 0
    
    // $2007 PPUDATA
    /// for buffered reads
    private var bufferedData: UInt8 = 0
    
    // MARK: Pixel Buffer
    static let screenWidth: Int = 256
    static let screenHeight: Int = 224
    static let emptyBuffer: [UInt32] = [UInt32].init(repeating: 0, count: PPU.screenWidth * PPU.screenHeight)
    private static let paletteColors: [UInt32] = [
        0x666666FF, 0x882A00FF, 0xA71214FF, 0xA4003BFF, 0x7E005CFF, 0x40006EFF, 0x00066CFF, 0x001D56FF,
        0x003533FF, 0x00480BFF, 0x005200FF, 0x084F00FF, 0x4D4000FF, 0x000000FF, 0x000000FF, 0x000000FF,
        0xADADADFF, 0xD95F15FF, 0xFF4042FF, 0xFE2775FF, 0xCC1AA0FF, 0x7B1EB7FF, 0x2031B5FF, 0x004E99FF,
        0x006D6BFF, 0x008738FF, 0x00930CFF, 0x328F00FF, 0x8D7C00FF, 0x000000FF, 0x000000FF, 0x000000FF,
        0xFFFEFFFF, 0xFFB064FF, 0xFF9092FF, 0xFF76C6FF, 0xFF6AF3FF, 0xCC6EFEFF, 0x7081FEFF, 0x229EEAFF,
        0x00BEBCFF, 0x00D888FF, 0x30E45CFF, 0x82E045FF, 0xDECD48FF, 0x4F4F4FFF, 0x000000FF, 0x000000FF,
        0xFFFEFFFF, 0xFFDFC0FF, 0xFFD2D3FF, 0xFFC8E8FF, 0xFFC2FBFF, 0xEAC4FEFF, 0xC5CCFEFF, 0xA5D8F7FF,
        0x94E5E4FF, 0x96EFCFFF, 0xABF4BDFF, 0xCCF3B3FF, 0xF2EBB5FF, 0xB8B8B8FF, 0x000000FF, 0x000000FF]
    
    /// colors in 0xBBGGRRAA format from Palette.colors
    private(set) var frontBuffer: [UInt32] = PPU.emptyBuffer
    /// colors in 0xBBGGRRAA format from Palette.colors
    private var backBuffer: [UInt32] = PPU.emptyBuffer
    private(set) var scanline: Int = 240
    
    init(mapper aMapper: MapperProtocol, state aState: PPUState? = nil)
    {
        self.mapper = aMapper
        self.mapperHasStep = aMapper.hasStep
        self.mapperHasExtendedNametableMapping = aMapper.hasExtendedNametableMapping
        if let safePPUState = aState
        {
            self.cycle = Int(safePPUState.cycle)
            self.frame = safePPUState.frame
            self.paletteData = safePPUState.paletteData
            self.nameTableData = safePPUState.nameTableData
            self.oamData = safePPUState.oamData
            self.v = safePPUState.v
            self.t = safePPUState.t
            self.x = safePPUState.x
            self.w = safePPUState.w
            self.f = safePPUState.f
            self.register = safePPUState.register
            self.nmiOccurred = safePPUState.nmiOccurred
            self.nmiOutput = safePPUState.nmiOutput
            self.nmiDelay = safePPUState.nmiDelay
            self.nameTableByte = safePPUState.nameTableByte
            self.attributeTableByte = safePPUState.attributeTableByte
            self.lowTileByte = safePPUState.lowTileByte
            self.highTileByte = safePPUState.highTileByte
            self.tileData = safePPUState.tileData
            self.spriteCount = Int(safePPUState.spriteCount)
            self.spritePatterns = safePPUState.spritePatterns
            self.spritePositions = safePPUState.spritePositions
            self.spritePriorities = safePPUState.spritePriorities
            self.spriteIndexes = safePPUState.spriteIndexes
            self.flagNameTable = safePPUState.flagNameTable
            self.flagIncrement = safePPUState.flagIncrement
            self.flagSpriteTable = safePPUState.flagSpriteTable
            self.flagBackgroundTable = safePPUState.flagBackgroundTable
            self.flagSpriteSize = safePPUState.flagSpriteSize
            self.flagMasterSlave = safePPUState.flagMasterSlave
            self.flagGrayscale = safePPUState.flagGrayscale
            self.flagShowLeftBackground = safePPUState.flagShowLeftBackground
            self.flagShowLeftSprites = safePPUState.flagShowLeftSprites
            self.flagShowBackground = safePPUState.flagShowBackground
            self.flagShowSprites = safePPUState.flagShowSprites
            self.flagRedTint = safePPUState.flagRedTint
            self.flagGreenTint = safePPUState.flagGreenTint
            self.flagBlueTint = safePPUState.flagBlueTint
            self.flagSpriteZeroHit = safePPUState.flagSpriteZeroHit
            self.flagSpriteOverflow = safePPUState.flagSpriteOverflow
            self.oamAddress = safePPUState.oamAddress
            self.bufferedData = safePPUState.bufferedData
            self.frontBuffer = safePPUState.frontBuffer
            self.scanline = Int(safePPUState.scanline)
        }
    }
}
