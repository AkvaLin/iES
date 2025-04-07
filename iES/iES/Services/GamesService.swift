//
//  GameService.swift
//  iES
//
//  Created by Никита Пивоваров on 01.10.2024.
//

import Foundation
import SwiftData

actor GamesService {
    
    static func getDescriptor(limit: Int = 0) -> FetchDescriptor<GameModel> {
        var descriptor = FetchDescriptor<GameModel>(sortBy: [SortDescriptor(\.lastTimePlayed, order: .reverse)])
        descriptor.fetchLimit = limit
        return descriptor
    }
    
    static func updateLastTimePlayed(for game: GameModel, context: ModelContext) {
        SwiftDataManager.updateLastTimePlayed(for: game, context: context) { _ in }
    }
    
    static func updateGames(games: [CloudServiceSaveModel.CloudServiceGameModel], context: ModelContext) {
        do {
            let descriptor = FetchDescriptor<GameModel>(sortBy: [SortDescriptor(\.id, order: .forward)])
            var models = try context.fetch(descriptor)
            let games = games.sorted { lhs, rhs in
                lhs.id < rhs.id
            }
            games.forEach { game in
                let searchedGame = models.first { $0.id == game.id }
                if let searchedGame {
                    updateGame(model: searchedGame, game: game)
                    models.removeAll { $0.id == game.id }
                } else {
                    let newGame = GameModel(
                        title: game.title,
                        imageData: game.imageData,
                        lastTimePlayed: game.lastTimePlayed,
                        gameData: game.gameData,
                        isAutoSaveEnabled: game.isAutoSaveEnabled
                    )
                    newGame.id = game.id
                    if let state = game.state {
                        newGame.setState(state)
                    }
                    context.insert(newGame)
                }
            }
            models.forEach { model in
                context.delete(model)
            }
        } catch {
            print(error)
        }
    }
    
    static private func updateGame(model: GameModel, game: CloudServiceSaveModel.CloudServiceGameModel) {
        model.title = game.title
        model.imageData = game.imageData
        model.lastTimePlayed = game.lastTimePlayed
        model.gameData = game.gameData
        model.isAutoSaveEnabled = game.isAutoSaveEnabled
        if let state = game.state {
            model.setState(state)
        }
    }
}

@Model
class GameModel {
    var id = UUID()
    var title: String
    @Attribute(.externalStorage) var imageData: Data?
    var lastTimePlayed: Date
    @Attribute(.externalStorage) var gameData: Data
    var isAutoSaveEnabled: Bool
    var state: EmulatorStateDTO?
    
    init(title: String, imageData: Data? = nil, lastTimePlayed: Date, gameData: Data, isAutoSaveEnabled: Bool = false, state: EmulatorStateDTO? = nil) {
        self.title = title
        self.imageData = imageData
        self.lastTimePlayed = lastTimePlayed
        self.gameData = gameData
        self.isAutoSaveEnabled = isAutoSaveEnabled
        self.state = state
    }
}

@Model
class EmulatorStateDTO {
    var date: Date
    var md5: String
    var cpuState: CPUStateDTO
    var apuState: APUStateDTO
    var ppuState: PPUStateDTO
    var mapperState: MapperStateDTO
    
    init(date: Date, md5: String, cpuState: CPUStateDTO, apuState: APUStateDTO, ppuState: PPUStateDTO, mapperState: MapperStateDTO) {
        self.date = date
        self.md5 = md5
        self.cpuState = cpuState
        self.apuState = apuState
        self.ppuState = ppuState
        self.mapperState = mapperState
    }
}

@Model
class CPUStateDTO {
    var ram: Data
    var a: UInt8
    var x: UInt8
    var y: UInt8
    var pc: UInt16
    var sp: UInt8
    var cycles: UInt64
    var flags: UInt8
    var interrupt: UInt8
    var stall: UInt64
    
    init(ram: Data, a: UInt8, x: UInt8, y: UInt8, pc: UInt16, sp: UInt8, cycles: UInt64, flags: UInt8, interrupt: UInt8, stall: UInt64) {
        self.ram = ram
        self.a = a
        self.x = x
        self.y = y
        self.pc = pc
        self.sp = sp
        self.cycles = cycles
        self.flags = flags
        self.interrupt = interrupt
        self.stall = stall
    }
    
    func setRam(_ ram: [UInt8]) { self.ram = convert_to_data(from: ram) }
    func getRam() -> [UInt8] { convert_to_array(from: ram) }
}

@Model
class APUStateDTO {
    var cycle: UInt64
    var framePeriod: UInt8
    var frameValue: UInt8
    var frameIRQ: Bool
    var audioBuffer: Data
    var audioBufferIndex: UInt32
    var pulse1: PulseState
    var pulse2: PulseState
    var triangle: TriangleState
    var noise: NoiseState
    var dmc: DMCState
    
    init(cycle: UInt64, framePeriod: UInt8, frameValue: UInt8, frameIRQ: Bool, audioBuffer: Data, audioBufferIndex: UInt32, pulse1: PulseState, pulse2: PulseState, triangle: TriangleState, noise: NoiseState, dmc: DMCState) {
        self.cycle = cycle
        self.framePeriod = framePeriod
        self.frameValue = frameValue
        self.frameIRQ = frameIRQ
        self.audioBuffer = audioBuffer
        self.audioBufferIndex = audioBufferIndex
        self.pulse1 = pulse1
        self.pulse2 = pulse2
        self.triangle = triangle
        self.noise = noise
        self.dmc = dmc
    }
    
    func setAudioBuffer(_ buffer: [Float32]) {
        self.audioBuffer = convert_to_data(from: buffer)
    }
    func getAudioBuffer() -> [Float32] {
        convert_to_array(from: audioBuffer)
    }
}

@Model
class PPUStateDTO {
    var cycle: UInt16
    var scanline: UInt16
    var frame: UInt64
    var paletteData: Data
    var nameTableData: Data
    var oamData: Data
    var v: UInt16
    var t: UInt16
    var x: UInt8
    var w: Bool
    var f: Bool
    var register: UInt8
    var nmiOccurred: Bool
    var nmiOutput: Bool
    var nmiDelay: UInt8
    var nameTableByte: UInt8
    var attributeTableByte: UInt8
    var lowTileByte: UInt8
    var highTileByte: UInt8
    var tileData: UInt64
    var spriteCount: UInt8
    var spritePatterns: Data
    var spritePositions: Data
    var spritePriorities: Data
    var spriteIndexes: Data
    var flagNameTable: UInt8
    var flagIncrement: Bool
    var flagSpriteTable: Bool
    var flagBackgroundTable: Bool
    var flagSpriteSize: Bool
    var flagMasterSlave: Bool
    var flagGrayscale: Bool
    var flagShowLeftBackground: Bool
    var flagShowLeftSprites: Bool
    var flagShowBackground: Bool
    var flagShowSprites: Bool
    var flagRedTint: Bool
    var flagGreenTint: Bool
    var flagBlueTint: Bool
    var flagSpriteZeroHit: UInt8
    var flagSpriteOverflow: UInt8
    var oamAddress: UInt8
    var bufferedData: UInt8
    var frontBuffer: Data
    
    init(cycle: UInt16, scanline: UInt16, frame: UInt64, paletteData: Data, nameTableData: Data, oamData: Data, v: UInt16, t: UInt16, x: UInt8, w: Bool, f: Bool, register: UInt8, nmiOccurred: Bool, nmiOutput: Bool, nmiDelay: UInt8, nameTableByte: UInt8, attributeTableByte: UInt8, lowTileByte: UInt8, highTileByte: UInt8, tileData: UInt64, spriteCount: UInt8, spritePatterns: Data, spritePositions: Data, spritePriorities: Data, spriteIndexes: Data, flagNameTable: UInt8, flagIncrement: Bool, flagSpriteTable: Bool, flagBackgroundTable: Bool, flagSpriteSize: Bool, flagMasterSlave: Bool, flagGrayscale: Bool, flagShowLeftBackground: Bool, flagShowLeftSprites: Bool, flagShowBackground: Bool, flagShowSprites: Bool, flagRedTint: Bool, flagGreenTint: Bool, flagBlueTint: Bool, flagSpriteZeroHit: UInt8, flagSpriteOverflow: UInt8, oamAddress: UInt8, bufferedData: UInt8, frontBuffer: Data) {
        self.cycle = cycle
        self.scanline = scanline
        self.frame = frame
        self.paletteData = paletteData
        self.nameTableData = nameTableData
        self.oamData = oamData
        self.v = v
        self.t = t
        self.x = x
        self.w = w
        self.f = f
        self.register = register
        self.nmiOccurred = nmiOccurred
        self.nmiOutput = nmiOutput
        self.nmiDelay = nmiDelay
        self.nameTableByte = nameTableByte
        self.attributeTableByte = attributeTableByte
        self.lowTileByte = lowTileByte
        self.highTileByte = highTileByte
        self.tileData = tileData
        self.spriteCount = spriteCount
        self.spritePatterns = spritePatterns
        self.spritePositions = spritePositions
        self.spritePriorities = spritePriorities
        self.spriteIndexes = spriteIndexes
        self.flagNameTable = flagNameTable
        self.flagIncrement = flagIncrement
        self.flagSpriteTable = flagSpriteTable
        self.flagBackgroundTable = flagBackgroundTable
        self.flagSpriteSize = flagSpriteSize
        self.flagMasterSlave = flagMasterSlave
        self.flagGrayscale = flagGrayscale
        self.flagShowLeftBackground = flagShowLeftBackground
        self.flagShowLeftSprites = flagShowLeftSprites
        self.flagShowBackground = flagShowBackground
        self.flagShowSprites = flagShowSprites
        self.flagRedTint = flagRedTint
        self.flagGreenTint = flagGreenTint
        self.flagBlueTint = flagBlueTint
        self.flagSpriteZeroHit = flagSpriteZeroHit
        self.flagSpriteOverflow = flagSpriteOverflow
        self.oamAddress = oamAddress
        self.bufferedData = bufferedData
        self.frontBuffer = frontBuffer
    }
    
    func getPaletteData() -> [UInt8] {
        convert_to_array(from: paletteData)
    }
    func setPaletteData(_ data: [UInt8]) {
        paletteData = convert_to_data(from: data)
    }
    
    func getNameTableData() -> [UInt8] {
        convert_to_array(from: nameTableData)
    }
    func setNameTableData(_ data: [UInt8]) {
        nameTableData = convert_to_data(from: data)
    }
    func getOamData() -> [UInt8] {
        convert_to_array(from: oamData)
    }
    func setOamData(_ data: [UInt8]) {
        oamData = convert_to_data(from: data)
    }
    func getSpritePatterns() -> [UInt32] {
        convert_to_array(from: spritePatterns)
    }
    func setSpritePatterns(_ data: [UInt32]) {
        spritePatterns = convert_to_data(from: data)
    }
    func getSpritePositions() -> [UInt8] {
        convert_to_array(from: spritePositions)
    }
    func setSpritePositions(_ data: [UInt8]) {
        spritePositions = convert_to_data(from: data)
    }
    func getSpritePriorities() -> [UInt8] {
        convert_to_array(from: spritePriorities)
    }
    func setSpritePriorities(_ data: [UInt8]) {
        spritePriorities = convert_to_data(from: data)
    }
    func getSpriteIndexes() -> [UInt8] {
        convert_to_array(from: spriteIndexes)
    }
    func setSpriteIndexes(_ data: [UInt8]) {
        spriteIndexes = convert_to_data(from: data)
    }
    func getFrontBuffer() -> [UInt32] {
        convert_to_array(from: frontBuffer)
    }
    func setFrontBuffer(_ data: [UInt32]) {
        frontBuffer = convert_to_data(from: data)
    }
}

@Model
class MapperStateDTO {
    var mirroringMode: UInt8
    var ints: Data
    var bools: Data
    var uint8s: Data
    var chr: Data
    
    init(mirroringMode: UInt8, ints: Data, bools: Data, uint8s: Data, chr: Data) {
        self.mirroringMode = mirroringMode
        self.ints = ints
        self.bools = bools
        self.uint8s = uint8s
        self.chr = chr
    }
    
    func getInts() -> [Int] {
        convert_to_array(from: ints)
    }
    func setInts(_ ints: [Int]) {
        self.ints = convert_to_data(from: ints)
    }
    func getBools() -> [Bool] {
        convert_to_array(from: bools)
    }
    func setBools(_ bools: [Bool]) {
        self.bools = convert_to_data(from: bools)
    }
    func getUint8s() -> [UInt8] {
        convert_to_array(from: uint8s)
    }
    func setUint8s(_ uint8s: [UInt8]) {
        self.uint8s = convert_to_data(from: uint8s)
    }
    func getChr() -> [UInt8] {
        convert_to_array(from: chr)
    }
    func setChr(_ chr: [UInt8]) {
        self.chr = convert_to_data(from: chr)
    }
}



func convert_to_data<T>(from array:[T]) -> Data {
    var p: UnsafeBufferPointer<T>? = nil
    array.withUnsafeBufferPointer { p = $0 }
    guard p != nil else {
        return Data()
    }
    return Data(buffer: p!)
}

func convert_to_array<T>(from data:Data) -> [T] {
    let capacity = data.count / MemoryLayout<T>.size
    let result = [T](unsafeUninitializedCapacity: capacity) {
        pointer, copied_count in
        let length_written = data.copyBytes(to: pointer)
        copied_count = length_written / MemoryLayout<T>.size
        assert(copied_count == capacity)
    }
    return result
}

extension EmulatorState {
    init(from dto: EmulatorStateDTO) {
        date = dto.date
        md5 = dto.md5
        cpuState = CPUState(from: dto.cpuState)
        apuState = APUState(from: dto.apuState)
        ppuState = PPUState(from: dto.ppuState)
        mapperState = MapperState(from: dto.mapperState)
    }
}

extension CPUState {
    init(from dto: CPUStateDTO) {
        ram = dto.getRam()
        a = dto.a
        x = dto.x
        y = dto.y
        pc = dto.pc
        sp = dto.sp
        cycles = dto.cycles
        flags = dto.flags
        interrupt = dto.interrupt
        stall = dto.stall
    }
}

extension APUState {
    init(from dto: APUStateDTO) {
        cycle = dto.cycle
        framePeriod = dto.framePeriod
        frameValue = dto.frameValue
        frameIRQ = dto.frameIRQ
        audioBuffer = dto.getAudioBuffer()
        audioBufferIndex = dto.audioBufferIndex
        pulse1 = dto.pulse1
        pulse2 = dto.pulse2
        triangle = dto.triangle
        noise = dto.noise
        dmc = dto.dmc
    }
}

extension PPUState {
    init(from dto: PPUStateDTO) {
        cycle = dto.cycle
        scanline = dto.scanline
        frame = dto.frame
        paletteData = dto.getPaletteData()
        nameTableData = dto.getNameTableData()
        oamData = dto.getOamData()
        v = dto.v
        t = dto.t
        x = dto.x
        w = dto.w
        f = dto.f
        register = dto.register
        nmiOccurred = dto.nmiOccurred
        nmiOutput = dto.nmiOutput
        nmiDelay = dto.nmiDelay
        nameTableByte = dto.nameTableByte
        attributeTableByte = dto.attributeTableByte
        lowTileByte = dto.lowTileByte
        highTileByte = dto.highTileByte
        tileData = dto.tileData
        spriteCount = dto.spriteCount
        spritePatterns = dto.getSpritePatterns()
        spritePositions = dto.getSpritePositions()
        spritePriorities = dto.getSpritePriorities()
        spriteIndexes = dto.getSpriteIndexes()
        flagNameTable = dto.flagNameTable
        flagIncrement = dto.flagIncrement
        flagSpriteTable = dto.flagSpriteTable
        flagBackgroundTable = dto.flagBackgroundTable
        flagSpriteSize = dto.flagSpriteSize
        flagMasterSlave = dto.flagMasterSlave
        flagGrayscale = dto.flagGrayscale
        flagShowLeftBackground = dto.flagShowLeftBackground
        flagShowLeftSprites = dto.flagShowLeftSprites
        flagShowBackground = dto.flagShowBackground
        flagShowSprites = dto.flagShowSprites
        flagRedTint = dto.flagRedTint
        flagGreenTint = dto.flagGreenTint
        flagBlueTint = dto.flagBlueTint
        flagSpriteZeroHit = dto.flagSpriteZeroHit
        flagSpriteOverflow = dto.flagSpriteOverflow
        oamAddress = dto.oamAddress
        bufferedData = dto.bufferedData
        frontBuffer = dto.getFrontBuffer()
    }
}

extension MapperState {
    init(from dto: MapperStateDTO) {
        mirroringMode = dto.mirroringMode
        ints = dto.getInts()
        bools = dto.getBools()
        uint8s = dto.getUint8s()
        chr = dto.getChr()
    }
}

extension GameModel {
    func setState(_ state: EmulatorState) {
        self.state = EmulatorStateDTO(
            date: state.date,
            md5: state.md5,
            cpuState: CPUStateDTO(
                ram: convert_to_data(from: state.cpuState.ram),
                a: state.cpuState.a,
                x: state.cpuState.x,
                y: state.cpuState.y,
                pc: state.cpuState.pc,
                sp: state.cpuState.sp,
                cycles: state.cpuState.cycles,
                flags: state.cpuState.flags,
                interrupt: state.cpuState.interrupt,
                stall: state.cpuState.stall
            ),
            apuState: APUStateDTO(
                cycle: state.apuState.cycle,
                framePeriod: state.apuState.framePeriod,
                frameValue: state.apuState.frameValue,
                frameIRQ: state.apuState.frameIRQ,
                audioBuffer: convert_to_data(from: state.apuState.audioBuffer),
                audioBufferIndex: state.apuState.audioBufferIndex,
                pulse1: state.apuState.pulse1,
                pulse2: state.apuState.pulse2,
                triangle: state.apuState.triangle,
                noise: state.apuState.noise,
                dmc: state.apuState.dmc
            ),
            ppuState: PPUStateDTO(
                cycle: state.ppuState.cycle,
                scanline: state.ppuState.scanline,
                frame: state.ppuState.frame,
                paletteData: convert_to_data(from: state.ppuState.paletteData),
                nameTableData: convert_to_data(from: state.ppuState.nameTableData),
                oamData: convert_to_data(from: state.ppuState.oamData),
                v: state.ppuState.v,
                t: state.ppuState.t,
                x: state.ppuState.x,
                w: state.ppuState.w,
                f: state.ppuState.f,
                register: state.ppuState.register,
                nmiOccurred: state.ppuState.nmiOccurred,
                nmiOutput: state.ppuState.nmiOutput,
                nmiDelay: state.ppuState.nmiDelay,
                nameTableByte: state.ppuState.nameTableByte,
                attributeTableByte: state.ppuState.attributeTableByte,
                lowTileByte: state.ppuState.lowTileByte,
                highTileByte: state.ppuState.highTileByte,
                tileData: state.ppuState.tileData,
                spriteCount: state.ppuState.spriteCount,
                spritePatterns: convert_to_data(from: state.ppuState.spritePatterns),
                spritePositions: convert_to_data(from: state.ppuState.spritePositions),
                spritePriorities: convert_to_data(from: state.ppuState.spritePriorities),
                spriteIndexes: convert_to_data(from: state.ppuState.spriteIndexes),
                flagNameTable: state.ppuState.flagNameTable,
                flagIncrement: state.ppuState.flagIncrement,
                flagSpriteTable: state.ppuState.flagSpriteTable,
                flagBackgroundTable: state.ppuState.flagBackgroundTable,
                flagSpriteSize: state.ppuState.flagSpriteSize,
                flagMasterSlave: state.ppuState.flagMasterSlave,
                flagGrayscale: state.ppuState.flagGrayscale,
                flagShowLeftBackground: state.ppuState.flagShowLeftBackground,
                flagShowLeftSprites: state.ppuState.flagShowLeftSprites,
                flagShowBackground: state.ppuState.flagShowBackground,
                flagShowSprites: state.ppuState.flagShowSprites,
                flagRedTint: state.ppuState.flagRedTint,
                flagGreenTint: state.ppuState.flagGreenTint,
                flagBlueTint: state.ppuState.flagBlueTint,
                flagSpriteZeroHit: state.ppuState.flagSpriteZeroHit,
                flagSpriteOverflow: state.ppuState.flagSpriteOverflow,
                oamAddress: state.ppuState.oamAddress,
                bufferedData: state.ppuState.bufferedData,
                frontBuffer: convert_to_data(from: state.ppuState.frontBuffer)
            ),
            mapperState: MapperStateDTO(
                mirroringMode: state.mapperState.mirroringMode,
                ints: convert_to_data(from: state.mapperState.ints),
                bools: convert_to_data(from: state.mapperState.bools),
                uint8s: convert_to_data(from: state.mapperState.uint8s),
                chr: convert_to_data(from: state.mapperState.chr)
            )
        )
    }
}
