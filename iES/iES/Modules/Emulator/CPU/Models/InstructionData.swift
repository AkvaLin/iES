//
//  InstructionData.swift
//  iES
//
//  Created by Никита Пивоваров on 14.07.2024.
//

import Foundation

struct InstructionData {
    
    /// CPU instruction
    let instruction: (_ stepData: StepData) -> ()
    
    /// the addressing mode of the instruction
    let mode: AddressingMode
    
    /// the number of cycles used by instruction
    let cycles: UInt8
    
    /// number of cycles the instruction takes if a page boundary is closed
    let pageCycles: UInt8
    
    /// the size of the instruction in bytes
    let bytes: UInt8
}
