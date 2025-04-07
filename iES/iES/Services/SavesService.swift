//
//  SavesService.swift
//  iES
//
//  Created by Никита Пивоваров on 01.10.2024.
//

import SwiftData

struct SavesService {
    static func saveState(_ dto: EmulatorStateDTO, state: EmulatorState) {
        dto.date = state.date
        dto.md5 = state.md5
        dto.cpuState.setRam(state.cpuState.ram)
        dto.cpuState.a = state.cpuState.a
        dto.cpuState.x = state.cpuState.x
        dto.cpuState.y = state.cpuState.y
        dto.cpuState.pc = state.cpuState.pc
        dto.cpuState.sp = state.cpuState.sp
        dto.cpuState.cycles = state.cpuState.cycles
        dto.cpuState.flags = state.cpuState.flags
        dto.cpuState.interrupt = state.cpuState.interrupt
        dto.cpuState.stall = state.cpuState.stall
        dto.apuState.cycle = state.apuState.cycle
        dto.apuState.framePeriod = state.apuState.framePeriod
        dto.apuState.frameValue = state.apuState.frameValue
        dto.apuState.frameIRQ = state.apuState.frameIRQ
        dto.apuState.setAudioBuffer(state.apuState.audioBuffer)
        dto.apuState.audioBufferIndex = state.apuState.audioBufferIndex
        dto.apuState.pulse1 = state.apuState.pulse1
        dto.apuState.pulse2 = state.apuState.pulse2
        dto.apuState.triangle = state.apuState.triangle
        dto.apuState.noise = state.apuState.noise
        dto.apuState.dmc = state.apuState.dmc
        dto.ppuState.cycle = state.ppuState.cycle
        dto.ppuState.scanline = state.ppuState.scanline
        dto.ppuState.frame = state.ppuState.frame
        dto.ppuState.setPaletteData(state.ppuState.paletteData)
        dto.ppuState.setNameTableData(state.ppuState.nameTableData)
        dto.ppuState.setOamData(state.ppuState.oamData)
        dto.ppuState.v = state.ppuState.v
        dto.ppuState.t = state.ppuState.t
        dto.ppuState.x = state.ppuState.x
        dto.ppuState.w = state.ppuState.w
        dto.ppuState.f = state.ppuState.f
        dto.ppuState.register = state.ppuState.register
        dto.ppuState.nmiOccurred = state.ppuState.nmiOccurred
        dto.ppuState.nmiOutput = state.ppuState.nmiOutput
        dto.ppuState.nmiDelay = state.ppuState.nmiDelay
        dto.ppuState.nameTableByte = state.ppuState.nameTableByte
        dto.ppuState.attributeTableByte = state.ppuState.attributeTableByte
        dto.ppuState.lowTileByte = state.ppuState.lowTileByte
        dto.ppuState.highTileByte = state.ppuState.highTileByte
        dto.ppuState.tileData = state.ppuState.tileData
        dto.ppuState.spriteCount = state.ppuState.spriteCount
        dto.ppuState.setSpritePatterns(state.ppuState.spritePatterns)
        dto.ppuState.setSpritePositions(state.ppuState.spritePositions)
        dto.ppuState.setSpritePriorities(state.ppuState.spritePriorities)
        dto.ppuState.setSpriteIndexes(state.ppuState.spriteIndexes)
        dto.ppuState.flagNameTable = state.ppuState.flagNameTable
        dto.ppuState.flagIncrement = state.ppuState.flagIncrement
        dto.ppuState.flagSpriteTable = state.ppuState.flagSpriteTable
        dto.ppuState.flagBackgroundTable = state.ppuState.flagBackgroundTable
        dto.ppuState.flagSpriteSize = state.ppuState.flagSpriteSize
        dto.ppuState.flagMasterSlave = state.ppuState.flagMasterSlave
        dto.ppuState.flagGrayscale = state.ppuState.flagGrayscale
        dto.ppuState.flagShowLeftBackground = state.ppuState.flagShowLeftBackground
        dto.ppuState.flagShowLeftSprites = state.ppuState.flagShowLeftSprites
        dto.ppuState.flagShowBackground = state.ppuState.flagShowBackground
        dto.ppuState.flagShowSprites = state.ppuState.flagShowSprites
        dto.ppuState.flagRedTint = state.ppuState.flagRedTint
        dto.ppuState.flagGreenTint = state.ppuState.flagGreenTint
        dto.ppuState.flagBlueTint = state.ppuState.flagBlueTint
        dto.ppuState.flagSpriteZeroHit = state.ppuState.flagSpriteZeroHit
        dto.ppuState.flagSpriteOverflow = state.ppuState.flagSpriteOverflow
        dto.ppuState.oamAddress = state.ppuState.oamAddress
        dto.ppuState.bufferedData = state.ppuState.bufferedData
        dto.ppuState.setFrontBuffer(state.ppuState.frontBuffer)
        dto.mapperState.mirroringMode = state.mapperState.mirroringMode
        dto.mapperState.setInts(state.mapperState.ints)
        dto.mapperState.setBools(state.mapperState.bools)
        dto.mapperState.setUint8s(state.mapperState.uint8s)
        dto.mapperState.setChr(state.mapperState.chr)
    }
}
