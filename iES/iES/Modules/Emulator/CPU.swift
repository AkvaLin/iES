//
//  CPU.swift
//  iES
//
//  Created by Никита Пивоваров on 01.06.2024.
//

import Foundation

struct CPU {
    
    private var ram: [UInt8] = Array(repeating: 0, count: 2048)
    
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
    private func flags() -> UInt8 {
        let flagByte: UInt8 = UInt8.init(fromLittleEndianBitArray: [self.c, self.z, self.i, self.d, self.b, self.u, self.v, self.n])
        return flagByte
    }
    
    /// sets processor status with bits arranged as c,z,i,d,b,u,v,n
    private mutating func set(flags: UInt8) {
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
    private mutating func setZ(value: UInt8) {
        self.z = (value == 0) ? true : false
    }
    
    /// sets the negative flag if the argument is negative
    private mutating func setN(value: UInt8) {
        self.n = (value & 0x80 != 0) ? true : false
    }
    
    private mutating func setZN(value: UInt8) {
        setZ(value: value)
        setN(value: value)
    }
}

// MARK: - Memory
extension CPU {
    
    private mutating func read(address: UInt16) -> UInt8
    {
        switch address {
        case 0x0000 ..< 0x2000:
            return self.ram[Int(address % 0x0800)]
        case 0x2000 ..< 0x4000:
            // TODO: PPU register
            return 0
        case 0x4014:
            // TODO: PPU register
            return 0
        case 0x4015:
            // TODO: APU register
            return 0
        case 0x4016:
            // TODO: Controller register
            return 0
        case 0x4017:
            // TODO: Controller register
            return 0
        case 0x4000 ..< 0x5000:
            // TODO: I/O registers
            return 0
        case 0x5000 ... 0xFFFF:
            // TODO: ...
            return 0
        default:
            return 0
        }
    }
}

// MARK: - 6502 functions
extension CPU {
    
    // MARK: arithmetic & logic
    
    // MARK: A,X,Y registers
    
    /// DEX - Decrement X Register
    private mutating func dex() {
        x &-= 1
        setZN(value: x)
    }
    
    /// LDA - Load accumulator
    private mutating func lda(address: UInt16) {
        a = read(address: address)
        setZN(value: a)
    }
    
    /// LDX - Load X Register
    private mutating func ldx(address: UInt16) {
        x = read(address: address)
        setZN(value: x)
    }
    
    /// LDY - Load Y Register
    private mutating func ldy(address: UInt16) {
        y = read(address: address)
        setZN(value: y)
    }
    
    /// TAX - Transfer Accumulator to X
    private mutating func tax() {
        x = a
        setZN(value: x)
    }
    
    /// TAY - Transfer Accumulator to Y
    private mutating func tay() {
        y = a
        setZN(value: y)
    }
    
    // MARK: status register
    
    // MARK: stack related
    
    // MARK: control flow
    
    // MARK: interrupts
}
