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
    
    /// - Important:  an optimization to prevent unnecessary Mapper object type lookups and mapper step calls during frequent PPU.step() calls
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
            guard nmiOccurred,
                  !oldValue,
                  nmiOutput
            else { return }
            
            // TODO: this fixes some games (e.g. Burger Time), but shouldn't be necessary - the timings are off somewhere
            nmiDelay = PPU.nmiMaximumDelay
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
        mapper = aMapper
        mapperHasStep = aMapper.hasStep
        mapperHasExtendedNametableMapping = aMapper.hasExtendedNametableMapping
        if let safePPUState = aState
        {
            cycle = Int(safePPUState.cycle)
            frame = safePPUState.frame
            paletteData = safePPUState.paletteData
            nameTableData = safePPUState.nameTableData
            oamData = safePPUState.oamData
            v = safePPUState.v
            t = safePPUState.t
            x = safePPUState.x
            w = safePPUState.w
            f = safePPUState.f
            register = safePPUState.register
            nmiOccurred = safePPUState.nmiOccurred
            nmiOutput = safePPUState.nmiOutput
            nmiDelay = safePPUState.nmiDelay
            nameTableByte = safePPUState.nameTableByte
            attributeTableByte = safePPUState.attributeTableByte
            lowTileByte = safePPUState.lowTileByte
            highTileByte = safePPUState.highTileByte
            tileData = safePPUState.tileData
            spriteCount = Int(safePPUState.spriteCount)
            spritePatterns = safePPUState.spritePatterns
            spritePositions = safePPUState.spritePositions
            spritePriorities = safePPUState.spritePriorities
            spriteIndexes = safePPUState.spriteIndexes
            flagNameTable = safePPUState.flagNameTable
            flagIncrement = safePPUState.flagIncrement
            flagSpriteTable = safePPUState.flagSpriteTable
            flagBackgroundTable = safePPUState.flagBackgroundTable
            flagSpriteSize = safePPUState.flagSpriteSize
            flagMasterSlave = safePPUState.flagMasterSlave
            flagGrayscale = safePPUState.flagGrayscale
            flagShowLeftBackground = safePPUState.flagShowLeftBackground
            flagShowLeftSprites = safePPUState.flagShowLeftSprites
            flagShowBackground = safePPUState.flagShowBackground
            flagShowSprites = safePPUState.flagShowSprites
            flagRedTint = safePPUState.flagRedTint
            flagGreenTint = safePPUState.flagGreenTint
            flagBlueTint = safePPUState.flagBlueTint
            flagSpriteZeroHit = safePPUState.flagSpriteZeroHit
            flagSpriteOverflow = safePPUState.flagSpriteOverflow
            oamAddress = safePPUState.oamAddress
            bufferedData = safePPUState.bufferedData
            frontBuffer = safePPUState.frontBuffer
            scanline = Int(safePPUState.scanline)
        }
    }
    
    mutating func read(address aAddress: UInt16) -> UInt8
    {
        let address = aAddress % 0x4000
        switch address {
        case 0x0000 ... 0x1FFF:
            return mapper.ppuRead(address: address)
        case 0x2000 ... 0x2FFF:
            if mapperHasExtendedNametableMapping
            {
                return mapper.ppuRead(address: aAddress)
            }
            else
            {
                return nameTableData[Int(adjustedPPUAddress(forOriginalAddress: address, withMirroringMode: mapper.mirroringMode) % 2048)]
            }
        case 0x3000 ... 0x3EFF:
            return nameTableData[Int(adjustedPPUAddress(forOriginalAddress: address, withMirroringMode: mapper.mirroringMode) % 2048)]
        case 0x3F00 ... 0x3FFF:
            return readPalette(address: (address % 32))
        default:
            return 0
        }
    }
    
    mutating func write(address aAddress: UInt16, value aValue: UInt8)
    {
        let address = aAddress % 0x4000
        switch address {
        case 0x0000 ... 0x1FFF:
            mapper.ppuWrite(address: address, value: aValue)
        case 0x2000 ... 0x2FFF:
            if mapperHasExtendedNametableMapping
            {
                mapper.ppuWrite(address: address, value: aValue)
            }
            else
            {
                nameTableData[Int(adjustedPPUAddress(forOriginalAddress: address, withMirroringMode: mapper.mirroringMode) % 2048)] = aValue
            }
        case 0x3000 ... 0x3EFF:
            nameTableData[Int(adjustedPPUAddress(forOriginalAddress: address, withMirroringMode: mapper.mirroringMode) % 2048)] = aValue
        case 0x3F00 ... 0x3FFF:
            writePalette(address: (address % 32), value: aValue)
        default:
            break
        }
    }
    
    private func adjustedPPUAddress(forOriginalAddress aOriginalAddress: UInt16, withMirroringMode aMirrorMode: MirroringMode) -> UInt16
    {
        let address: UInt16 = (aOriginalAddress - 0x2000) % 0x1000
        let addrRange: UInt16 = address / 0x0400
        let offset: UInt16 = address % 0x0400
        return 0x2000 + PPU.nameTableOffsetSequence[Int(aMirrorMode.rawValue)][Int(addrRange)] + offset
    }
    
    mutating func reset()
    {
        cycle = 340
        scanline = 240
        frame = 0
        writeControl(value: 0)
        writeMask(value: 0)
        writeOAMAddress(value: 0)
        backBuffer = PPU.emptyBuffer
        frontBuffer = PPU.emptyBuffer
    }
    
    private mutating func readPalette(address aAddress: UInt16) -> UInt8 // mutating because it makes a copy of PPU otherwise
    {
        let index: UInt16 = (aAddress >= 16 && aAddress % 4 == 0) ? aAddress - 16 : aAddress
        return paletteData[Int(index)]
    }

    private mutating func writePalette(address aAddress: UInt16, value aValue: UInt8)
    {
        let index: UInt16 = (aAddress >= 16 && aAddress % 4 == 0) ? aAddress - 16 : aAddress
        paletteData[Int(index)] = aValue
    }

    mutating func readRegister(address aAddress: UInt16) -> UInt8
    {
        switch aAddress
        {
        case 0x2002:
            return readStatus()
        case 0x2004:
            return readOAMData()
        case 0x2007:
            return readData()
        default: return 0
        }
    }

    mutating func writeRegister(address aAddress: UInt16, value aValue: UInt8)
    {
        register = aValue
        switch aAddress
        {
        case 0x2000:
            writeControl(value: aValue)
        case 0x2001:
            writeMask(value: aValue)
        case 0x2003:
            writeOAMAddress(value: aValue)
        case 0x2004:
            writeOAMData(value: aValue)
        case 0x2005:
            writeScroll(value: aValue)
        case 0x2006:
            writeAddress(value: aValue)
        case 0x2007:
            writeData(value: aValue)
        case 0x4014:
            // Write DMA (this is actually handled elsewhere when the CPU calls the PPU's writeOAMData function)
            break
        default: break
        }
    }

    // $2000: PPUCTRL
    private mutating func writeControl(value aValue: UInt8)
    {
        flagNameTable = (aValue >> 0) & 3
        flagIncrement = ((aValue >> 2) & 1) == 1
        flagSpriteTable = ((aValue >> 3) & 1) == 1
        flagBackgroundTable = ((aValue >> 4) & 1) == 1
        flagSpriteSize = ((aValue >> 5) & 1) == 1
        flagMasterSlave = ((aValue >> 6) & 1) == 1
        nmiOutput = ((aValue >> 7) & 1) == 1
        // TODO: should we set NMI Delay (nmiDelay) here if nmiOutput is true?
        // t: ....BA.. ........ = d: ......BA
        t = (t & 0xF3FF) | ((UInt16(aValue) & 0x03) << 10)
    }

    // $2001: PPUMASK
    private mutating func writeMask(value aValue: UInt8)
    {
        flagGrayscale = ((aValue >> 0) & 1) == 1
        flagShowLeftBackground = ((aValue >> 1) & 1) == 1
        flagShowLeftSprites = ((aValue >> 2) & 1) == 1
        flagShowBackground = ((aValue >> 3) & 1) == 1
        flagShowSprites = ((aValue >> 4) & 1) == 1
        flagRedTint = ((aValue >> 5) & 1) == 1
        flagGreenTint = ((aValue >> 6) & 1) == 1
        flagBlueTint = ((aValue >> 7) & 1) == 1
    }
    
    // $2002: PPUSTATUS
    private mutating func readStatus() -> UInt8
    {
        var result = register & 0x1F
        result |= flagSpriteOverflow << 5
        result |= flagSpriteZeroHit << 6
        if nmiOccurred
        {
            result |= 1 << 7
        }
        nmiOccurred = false
        // w:                   = 0
        w = false
        return result
    }

    // $2003: OAMADDR
    private mutating func writeOAMAddress(value aValue: UInt8)
    {
        oamAddress = aValue
    }

    // $2004: OAMDATA (read)
    private mutating func readOAMData() -> UInt8
    {
        let result: UInt8
        if (oamAddress & 0x03) == 0x02 // if sprite byte 2 of 0...3
        {
            // bits 2...4 should always come back as zero
            // (see http://wiki.nesdev.com/w/index.php/PPU_OAM )
            result = oamData[Int(oamAddress)] & 0xE3
        }
        else
        {
            result = oamData[Int(oamAddress)]
        }
        
        return result
    }

    // $2004: OAMDATA (write)
    private mutating func writeOAMData(value aValue: UInt8)
    {
        oamData[Int(oamAddress)] = aValue
        oamAddress &+= 1
    }

    // $2005: PPUSCROLL
    private mutating func writeScroll(value aValue: UInt8)
    {
        if w == false
        {
            // t: ........ ...HGFED = d: HGFED...
            // x:               CBA = d: .....CBA
            // w:                   = 1
            t = (t & 0xFFE0) | (UInt16(aValue) >> 3)
            x = aValue & 0x07
            w = true
        }
        else
        {
            // t: .CBA..HG FED..... = d: HGFEDCBA
            // w:                   = 0
            t = (t & 0x8FFF) | ((UInt16(aValue) & 0x07) << 12)
            t = (t & 0xFC1F) | ((UInt16(aValue) & 0xF8) << 2)
            w = false
        }
    }

    // $2006: PPUADDR
    private mutating func writeAddress(value aValue: UInt8)
    {
        if w == false {
            // t: ..FEDCBA ........ = d: ..FEDCBA
            // t: .X...... ........ = 0
            // w:                   = 1
            t = (t & 0x80FF) | ((UInt16(aValue) & 0x3F) << 8)
            w = true
        }
        else
        {
            // t: ........ HGFEDCBA = d: HGFEDCBA
            // v                    = t
            // w:                   = 0
            t = (t & 0xFF00) | UInt16(aValue)
            v = t
            w = false
        }
    }

    // $2007: PPUDATA (read)
    private mutating func readData() -> UInt8
    {
        var value = read(address: v)
        
        // emulate buffered reads
        if v % 0x4000 < 0x3F00
        {
            let buffered = bufferedData
            bufferedData = value
            value = buffered
        }
        else
        {
            bufferedData = read(address: v - 0x1000)
        }
        
        v &+= flagIncrement ? 32 : 1
        return value
    }

    // $2007: PPUDATA (write)
    private mutating func writeData(value aValue: UInt8)
    {
        write(address: v, value: aValue)
        v &+= flagIncrement ? 32 : 1
    }

    // $4014: OAMDMA
    
    /// called by the CPU with 256 bytes of OAM data for sprites and metadata
    mutating func writeOAMDMA(oamDMA aOamData: [UInt8])
    {
        for i in 0 ..< 256
        {
            oamData[Int(oamAddress)] = aOamData[i]
            oamAddress &+= 1
        }
    }
    
    // NTSC Timing Helper Functions

    private mutating func incrementX()
    {
        // increment hori(v)
        // if coarse X == 31
        if v & 0x001F == 31
        {
            // coarse X = 0
            v &= 0xFFE0
            // switch horizontal nametable
            v ^= 0x0400
        }
        else
        {
            // increment coarse X
            v &+= 1
        }
    }

    private mutating func incrementY()
    {
        // increment vert(v)
        // if fine Y < 7
        if v & 0x7000 != 0x7000
        {
            // increment fine Y
            v &+= 0x1000
        }
        else
        {
            // fine Y = 0
            v &= 0x8FFF
            // let y = coarse Y
            var y = (v & 0x03E0) >> 5
            if y == 29
            {
                // coarse Y = 0
                y = 0
                // switch vertical nametable
                v ^= 0x0800
            }
            else if y == 31
            {
                // coarse Y = 0, nametable not switched
                y = 0
            }
            else
            {
                // increment coarse Y
                y &+= 1
            }
            // put coarse Y back into v
            v = (v & 0xFC1F) | (y << 5)
        }
    }

    private mutating func copyX()
    {
        // hori(v) = hori(t)
        // v: .....F.. ...EDCBA = t: .....F.. ...EDCBA
        v = (v & 0xFBE0) | (t & 0x041F)
    }

    private mutating func copyY()
    {
        // vert(v) = vert(t)
        // v: .IHGF.ED CBA..... = t: .IHGF.ED CBA.....
        v = (v & 0x841F) | (t & 0x7BE0)
    }

    private mutating func setVerticalBlank()
    {
        swap(&frontBuffer, &backBuffer)
        nmiOccurred = true
    }

    private mutating func clearVerticalBlank()
    {
        nmiOccurred = false
    }

    private mutating func fetchNameTableByte()
    {
        let v = v
        let address = 0x2000 | (v & 0x0FFF)
        nameTableByte = read(address: address)
    }

    private mutating func fetchAttributeTableByte()
    {
        let v = v
        let address = 0x23C0 | (v & 0x0C00) | ((v >> 4) & 0x38) | ((v >> 2) & 0x07)
        let shift = ((v >> 4) & 4) | (v & 2)
        attributeTableByte = ((read(address: address) >> shift) & 3) << 2
    }

    private mutating func fetchLowTileByte()
    {
        let fineY = (v >> 12) & 7
        let table: UInt16 = flagBackgroundTable ? 0x1000 : 0
        let tile = nameTableByte
        let address = table + (UInt16(tile) * 16) + fineY
        lowTileByte = read(address: address)
    }

    private mutating func fetchHighTileByte()
    {
        let fineY = (v >> 12) & 7
        let table: UInt16 = flagBackgroundTable ? 0x1000 : 0
        let tile = nameTableByte
        let address = table + (UInt16(tile) * 16) + fineY
        highTileByte = read(address: address + 8)
    }

    private mutating func storeTileData()
    {
        var data: UInt32 = 0
        for _ in 0 ..< 8
        {
            let a = attributeTableByte
            let p1 = (lowTileByte & 0x80) >> 7
            let p2 = (highTileByte & 0x80) >> 6
            lowTileByte <<= 1
            highTileByte <<= 1
            data <<= 4
            data |= UInt32(a | p1 | p2)
        }
        tileData |= UInt64(data)
    }

    private func fetchTileData() -> UInt32
    {
        return UInt32(tileData >> 32)
    }

    private func backgroundPixel() -> UInt8
    {
        if !flagShowBackground
        {
            return 0
        }
        let data = fetchTileData() >> ((7 - x) * 4)
        return UInt8(data & 0x0F)
    }

    private func spritePixel() -> (UInt8, UInt8)
    {
        if !flagShowSprites
        {
            return (0, 0)
        }
        
        for i in 0 ..< spriteCount
        {
            var offset = (cycle - 1) - Int(spritePositions[i])
            if offset < 0 || offset > 7
            {
                continue
            }
            offset = 7 - offset
            let color = UInt8((spritePatterns[i] >> UInt8(offset * 4)) & 0x0F)
            if color % 4 == 0
            {
                continue
            }
            return (UInt8(i), color)
        }
        return (0, 0)
    }

    private mutating func renderPixel()
    {
        let x = cycle - 1
        let y = scanline - 8
        var background = backgroundPixel()
        var spritePixelTuple: (i: UInt8, sprite: UInt8) = spritePixel()
        
        if x < 8
        {
            if !flagShowLeftBackground
            {
                background = 0
            }
            
            if !flagShowLeftSprites
            {
                spritePixelTuple.sprite = 0
            }
        }
        
        let b: Bool = background % 4 != 0
        let s: Bool = spritePixelTuple.sprite % 4 != 0
        let color: UInt8
        
        if !b
        {
            color = s ? (spritePixelTuple.sprite | 0x10) : 0
        }
        else if !s
        {
            color = background
        }
        else
        {
            let spritePixelIndex: Int = Int(spritePixelTuple.i)
            
            if spriteIndexes[spritePixelIndex] == 0 && x < 255
            {
                flagSpriteZeroHit = 1
            }
            
            if spritePriorities[spritePixelIndex] == 0
            {
                color = spritePixelTuple.sprite | 0x10
            }
            else
            {
                color = background
            }
        }
        
        let index: Int = Int(readPalette(address: UInt16(color)) % 64)
        let paletteColor: UInt32 = PPU.paletteColors[index]
        backBuffer[(256 * y) + x] = paletteColor
    }

    private mutating func fetchSpritePattern(i aI: Int, row aRow: Int) -> UInt32
    {
        var row = aRow
        var tile = oamData[(aI * 4) + 1]
        let attributes = oamData[(aI * 4) + 2]
        var address: UInt16
        
        if !flagSpriteSize
        {
            if attributes & 0x80 == 0x80
            {
                row = 7 - row
            }
            
            let table: UInt16 = flagSpriteTable ? 0x1000 : 0
            address = table + (UInt16(tile) * 16) + UInt16(row)
        }
        else
        {
            if attributes & 0x80 == 0x80
            {
                row = 15 - row
            }
            let table = tile & 1
            tile &= 0xFE
            if row > 7
            {
                tile &+= 1
                row &-= 8
            }
            address = 0x1000 * UInt16(table) + UInt16(tile) * 16 + UInt16(row)
        }
        
        let a = (attributes & 3) << 2
        var lowTileByte = read(address: address)
        var highTileByte = read(address: address + 8)
        var data: UInt32 = 0
        
        for _ in 0 ..< 8
        {
            var p1: UInt8
            var p2: UInt8
            if attributes & 0x40 == 0x40
            {
                p1 = (lowTileByte & 1) << 0
                p2 = (highTileByte & 1) << 1
                lowTileByte >>= 1
                highTileByte >>= 1
            }
            else
            {
                p1 = (lowTileByte & 0x80) >> 7
                p2 = (highTileByte & 0x80) >> 6
                lowTileByte <<= 1
                highTileByte <<= 1
            }
            data <<= 4
            data |= UInt32(a | p1 | p2)
        }
        
        return data
    }

    private mutating func evaluateSprites()
    {
        let h: Int = flagSpriteSize ? 16 : 8
        var count: Int = 0
        
        for i in 0 ..< 64
        {
            let i4: Int = i * 4
            let y = oamData[i4 + 0]
            let a = oamData[i4 + 2]
            let x = oamData[i4 + 3]
            let row = scanline - Int(y)
            
            if row < 0 || row >= h
            {
                continue
            }
            
            if count < 8
            {
                spritePatterns[count] = fetchSpritePattern(i: i, row: row)
                spritePositions[count] = x
                spritePriorities[count] = (a >> 5) & 1
                spriteIndexes[count] = UInt8(i)
            }
            
            count += 1
        }
        
        if count > 8
        {
            count = 8
            flagSpriteOverflow = 1
        }
        
        spriteCount = count
    }

    /// Updates Cycle, ScanLine and Frame counters.
    private mutating func tick()
    {
        if cycle == 339 && scanline == 261 && (flagShowBackground || flagShowSprites) && f
        {
            cycle = 0
            scanline = 0
            frame += 1
            f = false
        }
        else
        {
            cycle += 1
            if cycle > 340
            {
                cycle = 0
                scanline += 1
                
                if scanline > 261
                {
                    scanline = 0
                    frame += 1
                    f.toggle()
                }
            }
        }
    }
    
    /// executes a single PPU cycle, and returns a Boolean indicating whether the CPU should trigger an NMI based on this cycle
    mutating func step() -> PPUStepResults
    {
        var shouldTriggerNMI: Bool = false
        
        if nmiDelay > 0
        {
            nmiDelay -= 1
            if nmiDelay == 0 && nmiOutput && nmiOccurred
            {
                shouldTriggerNMI = true
            }
        }
        
        tick()

        let renderingEnabled: Bool = flagShowBackground || flagShowSprites
        let preLine: Bool = scanline == 261
        
        if renderingEnabled
        {
            let visibleCycle: Bool = cycle >= 1 && cycle <= 256
            let preFetchCycle: Bool = cycle >= 321 && cycle <= 336
            let fetchCycle: Bool = preFetchCycle || visibleCycle
            
            let visibleLine: Bool = scanline < 240
            let renderLine: Bool = preLine || visibleLine
            let safeAreaScanline: Bool = scanline >= 8 && scanline < 232
            
            // background logic
            if safeAreaScanline && visibleCycle
            {
                renderPixel()
            }

            if renderLine && fetchCycle
            {
                tileData <<= 4
                switch cycle % 8
                {
                case 1:
                    fetchNameTableByte()
                case 3:
                    fetchAttributeTableByte()
                case 5:
                    fetchLowTileByte()
                case 7:
                    fetchHighTileByte()
                case 0:
                    storeTileData()
                default: break
                }
            }

            if preLine && cycle >= 280 && cycle <= 304
            {
                copyY()
            }

            if renderLine
            {
                if fetchCycle && cycle % 8 == 0
                {
                    incrementX()
                }

                if cycle == 256
                {
                    incrementY()
                }
                else if cycle == 257
                {
                    copyX()
                }
            }
            
            // sprite logic
            if cycle == 257
            {
                if visibleLine
                {
                    evaluateSprites()
                }
                else
                {
                    spriteCount = 0
                }
            }
        }

        // vblank logic
        if scanline == 241 && cycle == 1
        {
            setVerticalBlank()
        }

        if preLine && cycle == 1
        {
            clearVerticalBlank()
            flagSpriteZeroHit = 0
            flagSpriteOverflow = 0
        }

        let interruptRequestedByMapper: Interrupt?
        if mapperHasStep
        {
            interruptRequestedByMapper = mapper.step(input: MapperStepInput(ppuScanline: scanline, ppuCycle: cycle, ppuShowBackground: flagShowBackground, ppuShowSprites: flagShowSprites, ppuSpriteSize: flagSpriteSize))?.requestedCPUInterrupt
        }
        else
        {
            interruptRequestedByMapper = nil
        }
        
        return PPUStepResults(requestedCPUInterrupt: interruptRequestedByMapper ?? (shouldTriggerNMI ? .nmi : nil))
    }
}
