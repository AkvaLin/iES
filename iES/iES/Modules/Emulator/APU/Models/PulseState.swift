//
//  PulseState.swift
//  iES
//
//  Created by Никита Пивоваров on 10.01.2025.
//


import Foundation

struct PulseState: Codable {
    let enabled: Bool
    let lengthEnabled: Bool
    let lengthValue: UInt8
    let timerPeriod: UInt16
    let timerValue: UInt16
    let dutyMode: UInt8
    let dutyValue: UInt8
    let sweepReload: Bool
    let sweepEnabled: Bool
    let sweepNegate: Bool
    let sweepShift: UInt8
    let sweepPeriod: UInt8
    let sweepValue: UInt8
    let envelopeEnabled: Bool
    let envelopeLoop: Bool
    let envelopeStart: Bool
    let envelopePeriod: UInt8
    let envelopeValue:  UInt8
    let envelopeVolume: UInt8
    let constantVolume: UInt8
}
