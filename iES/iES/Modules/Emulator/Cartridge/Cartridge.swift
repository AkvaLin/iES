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
}
