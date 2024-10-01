//
//  SavesService.swift
//  iES
//
//  Created by Никита Пивоваров on 01.10.2024.
//

struct SavesService {
    
    static func saveState(_ state: EmulatorState) throws { }
    
    static func loadState() throws -> EmulatorState {
        return EmulatorState()
    }
}
