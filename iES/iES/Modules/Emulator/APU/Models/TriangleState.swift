//
//  TriangleState.swift
//  iES
//
//  Created by Никита Пивоваров on 10.01.2025.
//


import Foundation

struct TriangleState: Codable {
    let enabled: Bool
    let lengthEnabled: Bool
    let lengthValue: UInt8
    let timerPeriod: UInt16
    let timerValue: UInt16
    let dutyValue: UInt8
    let counterPeriod: UInt8
    let counterValue: UInt8
    let counterReload: Bool
}
