//
//  Emulator.swift
//  iES
//
//  Created by Никита Пивоваров on 12.01.2025.
//


import Foundation

struct Emulator
{
    // MARK: - Private Variables
    private let md5: String /// game MD5 hash
    private var cpu: CPU
    
    // MARK: - Computed Properties
    /// returns a 256x224 array of palette colors copies from the PPU's current screen buffer
    var screenBuffer: [UInt32] {
        cpu.ppu.frontBuffer
    }
    
    /// returns a ConsoleState struct containing the current state of the CPU, PPU, APU, and Mapper
    func consoleState() -> EmulatorState {
        EmulatorState(
            date: Date(),
            md5: md5,
            cpuState: cpu.cpuState,
            apuState: cpu.apu.apuState,
            ppuState: cpu.ppu.ppuState,
            mapperState: cpu.ppu.mapper.mapperState
        )
    }
    
    // MARK: - Life cycle
    init(
        withCartridge cartridge: Cartridge,
        sampleRate: SampleRate,
        audioFiltersEnabled: Bool,
        state: EmulatorState? = nil
    ) {
        self.md5 = cartridge.md5
        self.cpu = CPU(
            ppu: PPU(
                mapper: cartridge.mapper(withState: state?.mapperState),
                state: state?.ppuState
            ),
            apu: APU(
                withSampleRate: sampleRate,
                filtersEnabled: audioFiltersEnabled,
                state: state?.apuState
            ),
            controllers: [Controller(), Controller()],
            state: state?.cpuState
        )
    }
    
    // MARK: - Audio
    mutating func set(audioEngineDelegate: AudioEngineProtocol?) {
        cpu.apu.audioEngineDelegate = audioEngineDelegate
    }
    
    // MARK: - Buttons
    
    /// set an individual button to on or off for fontroller 0 or 1
    mutating func set(button: ControllerButton, enabled: Bool, forControllerAtIndex index: Int) {
        guard index < cpu.controllers.count else { return }
        self.cpu.controllers[index].set(buttonAtIndex: button.rawValue, enabled: enabled)
    }
    
    /// set all buttons at once for a given controller
    mutating func set(
        buttonUpPressed: Bool,
        buttonDownPressed: Bool,
        buttonLeftPressed: Bool,
        buttonRightPressed: Bool,
        buttonSelectPressed: Bool,
        buttonStartPressed: Bool,
        buttonBPressed: Bool,
        buttonAPressed: Bool,
        forControllerAtIndex index: Int
    ) {
        guard index < cpu.controllers.count else { return }
        cpu.controllers[index].set(
            buttons: [
                buttonAPressed,
                buttonBPressed,
                buttonSelectPressed,
                buttonStartPressed,
                buttonUpPressed,
                buttonDownPressed,
                buttonLeftPressed,
                buttonRightPressed
            ]
        )
    }
    
    /// reset the console and restart the currently-loaded game
    mutating func reset() {
        cpu.reset()
    }
    
    mutating func load(state: EmulatorState) {
        let sampleRate: SampleRate = cpu.apu.sampleRate
        let filtersEnabled: Bool = cpu.apu.filtersEnabled
        var mapper = cpu.ppu.mapper
        mapper.mapperState = state.mapperState
        
        cpu = CPU(
            ppu: PPU(
                mapper: mapper,
                state: state.ppuState
            ),
            apu: APU(
                withSampleRate: sampleRate,
                filtersEnabled: filtersEnabled,
                state: state.apuState
            ),
            controllers: [Controller(), Controller()],
            state: state.cpuState
        )
    }
    
    // MARK: - Timing
    
    mutating func stepSeconds(seconds: Float64) {
        var cycles = Int(Float64(CPU.frequency) * seconds)
        while cycles > 0 {
            cycles -= cpu.step()
        }
    }
}
