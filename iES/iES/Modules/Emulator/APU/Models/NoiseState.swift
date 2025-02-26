//
//  NoiseState.swift
//  iES
//
//  Created by Никита Пивоваров on 10.01.2025.
//


import Foundation

struct NoiseState: Codable {
    let enabled: Bool
    let mode: Bool
    let shiftRegister: UInt16
    let lengthEnabled: Bool
    let lengthValue: UInt8
    let timerPeriod: UInt16
    let timerValue: UInt16
    let envelopeEnabled: Bool
    let envelopeLoop: Bool
    let envelopeStart: Bool
    let envelopePeriod: UInt8
    let envelopeValue: UInt8
    let envelopeVolume: UInt8
    let constantVolume: UInt8
}
