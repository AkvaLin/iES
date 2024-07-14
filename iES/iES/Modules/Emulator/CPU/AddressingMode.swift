//
//  AddressingMode.swift
//  iES
//
//  Created by Никита Пивоваров on 14.07.2024.
//

import Foundation

enum AddressingMode: UInt8 {
    case absolute, absoluteXIndexed, absoluteYIndexed, accumulator, immediate, implied, xIndexedIndirect, indirect, indirectYIndexed, relative, zeropage, zeroPageXIndexed, zeroPageYIndexed
}
