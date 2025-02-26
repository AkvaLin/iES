//
//  EmulatorState.swift
//  iES
//
//  Created by Никита Пивоваров on 12.01.2025.
//


import Foundation
import SwiftData

@Model
class EmulatorState {
    var date: Date
    var md5: String
    var cpuState: CPUState
    var apuState: APUState
    var ppuState: PPUState
    var mapperState: MapperState
    
    init(date: Date, md5: String, cpuState: CPUState, apuState: APUState, ppuState: PPUState, mapperState: MapperState) {
        self.date = date
        self.md5 = md5
        self.cpuState = cpuState
        self.apuState = apuState
        self.ppuState = ppuState
        self.mapperState = mapperState
    }
}
