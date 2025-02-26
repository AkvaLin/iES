//
//  CPUState.swift
//  iES
//
//  Created by Никита Пивоваров on 10.01.2025.
//


import Foundation

struct CPUState: Codable {
    let ram: [UInt8]
    let a: UInt8
    let x: UInt8
    let y: UInt8
    let pc: UInt16
    let sp: UInt8
    let cycles: UInt64
    let flags: UInt8
    let interrupt: UInt8
    let stall: UInt64
}
