//
//  SavesService.swift
//  iES
//
//  Created by Никита Пивоваров on 01.10.2024.
//

import SwiftData

struct SavesService {
    static func saveState(_ state: EmulatorState, newState: EmulatorState) {
        state.date = newState.date
        state.md5 = newState.md5
        state.cpuState = newState.cpuState
        state.ppuState = newState.ppuState
        state.apuState = newState.apuState
        state.mapperState = newState.mapperState
    }
}
