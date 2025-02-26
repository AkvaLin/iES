//
//  DMCState.swift
//  iES
//
//  Created by Никита Пивоваров on 10.01.2025.
//


import Foundation

struct DMCState: Codable {
    let enabled: Bool
    let value: UInt8
    let sampleAddress: UInt16
    let sampleLength: UInt16
    let currentAddress: UInt16
    let currentLength: UInt16
    let shiftRegister: UInt8
    let bitCount: UInt8
    let tickPeriod: UInt8
    let tickValue: UInt8
    let loop: Bool
    let irq: Bool
}
