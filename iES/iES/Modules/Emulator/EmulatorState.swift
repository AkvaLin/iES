//
//  EmulatorState.swift
//  iES
//
//  Created by Никита Пивоваров on 12.01.2025.
//


import Foundation

struct EmulatorState: Codable {
    var date: Date
    var md5: String
    var cpuState: CPUState
    var apuState: APUState
    var ppuState: PPUState
    var mapperState: MapperState
}
