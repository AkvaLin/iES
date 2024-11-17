//
//  Emulator.swift
//  iES
//
//  Created by Никита Пивоваров on 01.10.2024.
//

import Foundation

struct Emulator {
    
    // MARK: - Private Variables
    private let md5: String /// game MD5 hash
    private var cpu: CPU
    
    // MARK: - Computed Properties
    /// returns a 256x224 array of palette colors copies from the PPU's current screen buffer
    var screenBuffer: [UInt32]
    {
        self.cpu.ppu.frontBuffer
    }
    
    /// returns a EmulatorState struct containing the current state of the CPU, PPU, APU, and Mapper
    func emulatorState(isAutoSave aIsAutosave: Bool) -> EmulatorState
    {
        return EmulatorState()
    }
    
    // MARK: - Life cycle
    init(withCartridge cartridge: Cartridge, state: EmulatorState? = nil)
    {
        self.md5 = cartridge.md5
        self.cpu = CPU(ppu: PPU(mapper: cartridge.mapper(withState: nil)))
    }
    
    // MARK: - Buttons
    
    mutating func load(state: EmulatorState) {
        
    }
    
    // MARK: - Timing
    
    mutating func stepSeconds(seconds aSeconds: Float64)
    {
        var cycles = Int(Float64(CPU.frequency) * aSeconds)
        while cycles > 0
        {
            cycles -= self.cpu.step()
        }
    }
}
