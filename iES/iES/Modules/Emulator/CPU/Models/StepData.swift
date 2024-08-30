//
//  StepData.swift
//  iES
//
//  Created by Никита Пивоваров on 14.07.2024.
//

import Foundation

struct StepData {
    
    /// memory address
    let address: UInt16
    
    /// addressing mode
    let mode: AddressingMode
    
    /// program counter
    let pc: UInt16
}
