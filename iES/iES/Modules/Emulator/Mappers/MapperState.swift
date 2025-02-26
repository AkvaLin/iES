//
//  MapperState.swift
//  iES
//
//  Created by Никита Пивоваров on 17.11.2024.
//

import Foundation

struct MapperState: Codable {
    let mirroringMode: UInt8
    let ints: [Int]
    let bools: [Bool]
    let uint8s: [UInt8]
    let chr: [UInt8]
}
