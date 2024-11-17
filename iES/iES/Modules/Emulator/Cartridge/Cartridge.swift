//
//  Cartridge.swift
//  iES
//
//  Created by Никита Пивоваров on 14.07.2024.
//

import Foundation

protocol CartridgeProtocol {
    var header: RomHeader { get }
    var prgBlocks: [[UInt8]] { get }
    var chrBlocks: [[UInt8]] { get set }
}

struct Cartridge: CartridgeProtocol {
    
    let md5: String
    let header: RomHeader
    let trainerData: Data
    let prgBlocks: [[UInt8]]
    var chrBlocks: [[UInt8]]
    let isValid: Bool
    
    init(from data: Data) {
        let header = RomHeader(from: data.prefix(RomHeader.sizeInBytes))
        self.header = header
        self.md5 = data.md5
        
        guard header.isValid else {
            self.chrBlocks = []
            self.prgBlocks = []
            self.trainerData = Data()
            self.isValid = false
            
            return
        }
        
        let prgBlockSize = 16384
        let chrBlockSize = 8192
        let headerSize = RomHeader.sizeInBytes
        let trainerSize = header.hasTrainer ? 512 : 0
        let totalPrgSize = Int(header.numPrgBlocks) * prgBlockSize
        let totalChrSize = Int(header.numChrBlocks) * chrBlockSize
        let trainerOffset = RomHeader.sizeInBytes
        let prgOffset = trainerOffset + trainerSize
        let chrOffset = prgOffset + totalPrgSize
        
        let expectedFileSizeOfEntireRomInBytes: Int = headerSize + trainerSize + totalPrgSize + totalChrSize
        
        guard expectedFileSizeOfEntireRomInBytes == data.count
            else
        {
            self.chrBlocks = []
            self.prgBlocks = []
            self.trainerData = Data()
            self.isValid = false
            return
        }
        
        self.trainerData = header.hasTrainer ? data.subdata(in: trainerOffset ..< prgOffset) : Data()
        
        var pBlocks: [[UInt8]] = []
        for i in 0 ..< Int(header.numPrgBlocks)
        {
            let offset: Int = prgOffset + (i * prgBlockSize)
            pBlocks.append([UInt8](data.subdata(in: offset ..< offset + prgBlockSize)))
        }
        
        var cBlocks: [[UInt8]] = []
        for i in 0 ..< Int(header.numChrBlocks)
        {
            let offset: Int = chrOffset + (i * chrBlockSize)
            cBlocks.append([UInt8](data.subdata(in: offset ..< offset + chrBlockSize)))
        }
        
        self.prgBlocks = pBlocks
        self.chrBlocks = cBlocks
        
        self.isValid = true
    }
    
    func mapper(withState state: MapperState? = nil) -> MapperProtocol
    {
        guard let safeMapperIdentifier: MapperIdentifier = self.header.mapperIdentifier,
            safeMapperIdentifier.isSupported
        else
        {
            return Mapper_UnsupportedPlaceholder(withCartridge: self)
        }
        
        switch self.header.mapperIdentifier
        {
        case .NROM:
            return Mapper_NROM(withCartridge: self, state: state)
        case .UxROM:
            return Mapper_UNROM(withCartridge: self, state: state)
        case .MMC1:
            return Mapper_MMC1(withCartridge: self, state: state)
        case .CNROM:
            return Mapper_CNROM(withCartridge: self, state: state)
        case .MMC3:
            return Mapper_MMC3(withCartridge: self, state: state)
        case .AxROM:
            return Mapper_AxROM(withCartridge: self, state: state)
        case .MMC2:
            return Mapper_MMC2(withCartridge: self, state: state)
        case .MMC4:
            return Mapper_MMC4(withCartridge: self, state: state)
        case .ColorDreams:
            return Mapper_ColorDreams(withCartridge: self, state: state)
        case .MMC5:
            return Mapper_MMC5(withCartridge: self, state: state)
        case .VRC2b_VRC4e_VRC4f:
            return Mapper_VRC2b_VRC4e_VRC4f(withCartridge: self, state: state)
        case .VRC2c_VRC4b_VRC4d:
            return Mapper_VRC2c_VRC4b_VRC4d(withCartridge: self, state: state)
        case .VRC7:
            return Mapper_VRC7(withCartridge: self, state: state)
        case .GxROM:
            return Mapper_GxROM(withCartridge: self, state: state)
        case ._078:
            return Mapper_78(withCartridge: self, state: state)
        case ._087:
            return Mapper_87(withCartridge: self, state: state)
        case .TxSROM:
            return Mapper_TxSROM(withCartridge: self, state: state)
        case .TQROM:
            return Mapper_TQROM(withCartridge: self, state: state)
        case .Namcot118_TengenMimic1:
            return Mapper_Namcot118_TengenMimic1(withCartridge: self, state: state)
        case .NTDEC_2722:
            return Mapper_NTDEC2722(withCartridge: self, state: state)
        case .CamericaQuattro:
            return Mapper_CamericaQuattro(withCartridge: self, state: state)
        default:
            return Mapper_UnsupportedPlaceholder(withCartridge: self, state: state)
        }
    }
}
