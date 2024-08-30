//
//  MapperProtocol.swift
//  iES
//
//  Created by Никита Пивоваров on 14.07.2024.
//

import Foundation
import os

struct MapperStepResults {
    let requestedCPUInterrupt: Interrupt?
}

struct MapperStepInput {
    let ppuScanline: Int
    let ppuCycle: Int
    let ppuShowBackground: Bool
    let ppuShowSprites: Bool
    let ppuSpriteSize: Bool /// false = 8x8 sprites, true = 8x16 sprites
}

protocol MapperProtocol {
    /// returns a Bool indicating whether the step function returns anything
    var hasStep: Bool { get }
    
    /// returns a Bool indicating whether the mapper implements its own nametable mapping by responding to 0x2000 - 0x2FFF
    var hasExtendedNametableMapping: Bool { get }
    
    /// returns the current mirroring mode for the mapper.  the mirroring mode is initially set to whatever the NES ROM iNES header specifies, but some mappers allow this to be changed at runtime
    var mirroringMode: MirroringMode { get }
    
    /// read a given mapper address from the CPU (must be an address in the range 0x6000 ... 0xFFFF)
    mutating func cpuRead(address: UInt16) -> UInt8 // 0x6000 ... 0xFFFF
    
    /// write to a given mapper address from the CPU (must be an address in the range 0x5000 ... 0xFFFF)
    mutating func cpuWrite(address: UInt16, value: UInt8) // 0x6000 ... 0xFFFF
    
    /// read a given mapper address from the PPU (must be an address in the range 0x0000 ... 0x1FFF, or 0x0000 ... 0x2FFF if the mapper supports extended nametable mapping)
    mutating func ppuRead(address: UInt16) -> UInt8 // 0x0000 ... 0x1FFF, or 0x0000 ... 0x2FFF if extended nametable mapping is supported
    
    /// write to a given mapper address from the PPU (must be an address in the range 0x0000 ... 0x1FFF, or 0x0000 ... 0x2FFF if the mapper supports extended nametable mapping)
    mutating func ppuWrite(address: UInt16, value: UInt8) // 0x0000 ... 0x1FFF, or 0x0000 ... 0x2FFF if extended nametable mapping is supported
    
    /// run a single cycle on the mapper, corresponding with a PPU cycle, if the mapper needs to interface with the CPU or PPU
    mutating func step(input: MapperStepInput) -> MapperStepResults?
}

