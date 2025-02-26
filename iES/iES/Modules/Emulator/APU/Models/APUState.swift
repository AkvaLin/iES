//
//  APUState.swift
//  iES
//
//  Created by Никита Пивоваров on 10.01.2025.
//


import Foundation

struct APUState: Codable {
    let cycle: UInt64
    let framePeriod: UInt8
    let frameValue: UInt8
    let frameIRQ: Bool
    let audioBuffer: [Float32]
    let audioBufferIndex: UInt32
    let pulse1: PulseState
    let pulse2: PulseState
    let triangle: TriangleState
    let noise: NoiseState
    let dmc: DMCState
}
