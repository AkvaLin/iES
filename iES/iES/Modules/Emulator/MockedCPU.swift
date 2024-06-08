//
//  MockedCPU.swift
//  iES
//
//  Created by Никита Пивоваров on 08.06.2024.
//

import Foundation

struct MockedCPU {
    
    public var ram: [UInt8] = Array(repeating: 0, count: 2048)
    
    /// number of cycles
    public var cycles: UInt64 = 0
    
    /// program counter
    public var pc: UInt16 = 0
    
    /// stack pointer
    public var sp: UInt8 = 0
    
    // MARK: Registers
    
    /// accumulator
    public var a: UInt8 = 0
    
    /// x register
    public var x: UInt8 = 0
    
    /// y register
    public var y: UInt8 = 0
    
    // MARK: Flags (processor status)
    
    /// carry flag
    public var c: Bool = false
    
    /// zero flag
    public var z: Bool = false
    
    /// interrupt disable flag
    public var i: Bool = false
    
    /// decimal mode flag
    public var d: Bool = false
    
    /// break command flag
    public var b: Bool = false
    
    /// unused flag
    public var u: Bool = false
    
    /// overflow flag
    public var v: Bool = false
    
    /// negative flag
    public var n: Bool = false
}

// MARK: - Flag operations

extension MockedCPU {
    /// returns a UInt8 with flag bits arranged as c,z,i,d,b,u,v,n
    public func flags() -> UInt8 {
        let flagByte: UInt8 = UInt8.init(fromLittleEndianBitArray: [self.c, self.z, self.i, self.d, self.b, self.u, self.v, self.n])
        return flagByte
    }
    
    /// sets processor status with bits arranged as c,z,i,d,b,u,v,n
    public mutating func set(flags: UInt8) {
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
    public mutating func setZ(value: UInt8) {
        self.z = (value == 0) ? true : false
    }
    
    /// sets the negative flag if the argument is negative
    public mutating func setN(value: UInt8) {
        self.n = (value & 0x80 != 0) ? true : false
    }
    
    public mutating func setZN(value: UInt8) {
        setZ(value: value)
        setN(value: value)
    }
}

// MARK: - Memory
extension MockedCPU {
    
    public mutating func read(address: UInt16) -> UInt8
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
extension MockedCPU {
    
    // MARK: arithmetic & logic
    
    // MARK: A,X,Y registers
    
    /// LDA - Load accumulator
    public mutating func lda(address: UInt16) {
        a = read(address: address)
        setZN(value: a)
    }
    
    /// TAX - Transfer Accumulator to X
    public mutating func tax() {
        x = a
        setZN(value: x)
    }
    
    /// TAY - Transfer Accumulator to Y
    public mutating func tay() {
        y = a
        setZN(value: y)
    }
    
    // MARK: status register
    
    // MARK: stack related
    
    // MARK: control flow
    
    // MARK: interrupts
}
