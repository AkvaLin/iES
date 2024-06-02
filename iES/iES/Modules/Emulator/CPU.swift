//
//  CPU.swift
//  iES
//
//  Created by Никита Пивоваров on 01.06.2024.
//

import Foundation

struct CPU {
    
    /// number of cycles
    private(set) var cycles: UInt64 = 0
    
    /// program counter
    private var pc: UInt16 = 0
    
    /// stack pointer
    private var sp: UInt8 = 0
    
    // MARK: Registers
    
    /// accumulator
    private var a: UInt8 = 0
    
    /// x register
    private var x: UInt8 = 0
    
    /// y register
    private var y: UInt8 = 0

    // MARK: Flags (processor status)
    
    /// carry flag
    private var c: Bool = false
    
    /// zero flag
    private var z: Bool = false
    
    /// interrupt disable flag
    private var i: Bool = false
    
    /// decimal mode flag
    private var d: Bool = false
    
    /// break command flag
    private var b: Bool = false
    
    /// unused flag
    private var u: Bool = false
    
    /// overflow flag
    private var v: Bool = false
    
    /// negative flag
    private var n: Bool = false
}

// MARK: - Flag operations

extension CPU {
    /// returns a UInt8 with flag bits arranged as c,z,i,d,b,u,v,n
    private func flags() -> UInt8
    {
        let flagByte: UInt8 = UInt8.init(fromLittleEndianBitArray: [self.c, self.z, self.i, self.d, self.b, self.u, self.v, self.n])
        return flagByte
    }
    
    /// sets processor status with bits arranged as c,z,i,d,b,u,v,n
    private mutating func set(flags: UInt8)
    {
        let bits = flags.littleEndianBitArray
        self.c = bits[0]
        self.z = bits[1]
        self.i = bits[2]
        self.d = bits[3]
        self.b = bits[4]
        self.u = bits[5]
        self.v = bits[6]
        self.n = bits[7]
    }
    
    /// sets the zero flag if the argument is zero
    private mutating func setZ(value aValue: UInt8)
    {
        self.z = (aValue == 0) ? true : false
    }
    
    /// sets the negative flag if the argument is negative
    private mutating func setN(value aValue: UInt8)
    {
        self.n = (aValue & 0x80 != 0) ? true : false
    }
}

// MARK: - 6502 functions
extension CPU {
    
    // MARK: arithmetic & logic

    // MARK: A,X,Y registers
    
    // MARK: status register
    
    // MARK: stack related
    
    // MARK: control flow
    
    // MARK: interrupts
}
