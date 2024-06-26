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
    
    /**
     compares two values and sets zero, negative and carry flags
     - parameter firstValue: the main value that will be compared
     - parameter secondValue: the value to be compared with
     */
    private mutating func compare(firstValue: UInt8, secondValue: UInt8)
    {
        self.setZN(value: firstValue &- secondValue)
        self.c = firstValue >= secondValue ? true : false
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
    
    private mutating func write(address: UInt16, value: UInt8) {
        switch address {
        case 0x0000 ..< 0x2000:
            ram[Int(address % 0x0800)] = value
            // TODO: other cases
        default:
            break
        }
    }
}

// MARK: - 6502 functions
extension CPU {
    
    /// NOP - No Operation
    private mutating func nop() { }
    
    // MARK: - arithmetic & logic
    
    /// ADC - Add with Carry
    private mutating func adc(stepData: StepData) {
        let a = a
        let b = read(address: stepData.address)
        let c: UInt8 = c ? 1 : 0
        self.a = a &+ b &+ c
        self.setZN(value: self.a)
        self.c = Int(a) + Int(b) + Int(c) > 0xFF
        self.v = ((a ^ b) & 0x80) == 0 && ((a ^ self.a) & 0x80) != 0
    }
    
    /// AND - Logical AND
    private mutating func and(stepData: StepData) {
        a = a & read(address: stepData.address)
        setZN(value: a)
    }
    
    /// ASL - Arithmetic Shift Left
    private mutating func asl(stepData: StepData) {
        if stepData.mode == .accumulator
        {
            c = ((a >> 7) & 1) == 1
            a <<= 1
            setZN(value: a)
        }
        else
        {
            var value = read(address: stepData.address)
            c = ((value >> 7) & 1) == 1
            value <<= 1
            write(address: stepData.address, value: value)
            setZN(value: value)
        }
    }
    
    /// BIT - Bit Test
    private mutating func bit(stepData: StepData) {
        let value = read(address: stepData.address)
        v = ((value >> 6) & 1) == 1
        setZ(value: value & a)
        setN(value: value)
    }
    
    /// CMP - Compare
    private mutating func cmp(stepData: StepData) {
        let value = read(address: stepData.address)
        compare(firstValue: a, secondValue: value)
    }
    
    /// DEC - Decrement Memory
    private mutating func dec(stepData: StepData) {
        let value = read(address: stepData.address) &- 1
        write(address: stepData.address, value: value)
        setZN(value: value)
    }
    
    /// EOR - Exclusive OR
    private mutating func eor(stepData: StepData) {
        a = a ^ read(address: stepData.address)
        setZN(value: a)
    }
    
    /// LSR - Logical Shift Right
    private mutating func lsr(stepData: StepData) {
        if stepData.mode == .accumulator
        {
            c = (a & 1) == 1
            a >>= 1
            setZN(value: a)
        }
        else
        {
            var value = read(address: stepData.address)
            c = (value & 1) == 1
            value >>= 1
            write(address: stepData.address, value: value)
            setZN(value: value)
        }
    }
    
    /// ORA - Logical Inclusive OR
    private mutating func ora(stepData: StepData) {
        a = a | read(address: stepData.address)
        setZN(value: a)
    }
    
    /// ROL - Rotate Left
    private mutating func rol(stepData: StepData) {
        if stepData.mode == .accumulator
        {
            let c: UInt8 = self.c ? 1 : 0
            self.c = ((self.a >> 7) & 1) == 1
            self.a = (self.a << 1) | c
            self.setZN(value: self.a)
        }
        else
        {
            let c: UInt8 = self.c ? 1 : 0
            var value = self.read(address: stepData.address)
            self.c = ((value >> 7) & 1) == 1
            value = (value << 1) | c
            self.write(address: stepData.address, value: value)
            self.setZN(value: value)
        }
    }
    
    /// ROR - Rotate Right
    private mutating func ror(stepData: StepData) {
        if stepData.mode == .accumulator
        {
            let c: UInt8 = self.c ? 1 : 0
            self.c = (self.a & 1) == 1
            self.a = (self.a >> 1) | (c << 7)
            self.setZN(value: self.a)
        }
        else
        {
            let c: UInt8 = self.c ? 1 : 0
            var value = self.read(address: stepData.address)
            self.c = (value & 1) == 1
            value = (value >> 1) | (c << 7)
            self.write(address: stepData.address, value: value)
            self.setZN(value: value)
        }
    }
    
    /// SBC - Subtract with Carry
    private mutating func sbc(stepData: StepData) {
        let a: UInt8 = self.a
        let b: UInt8 = self.read(address: stepData.address)
        let c: UInt8 = self.c ? 1 : 0
        self.a = a &- b &- (1 - c)
        self.setZN(value: self.a)
        self.c = Int(a) - Int(b) - Int(1 - c) >= 0
        self.v = ((a ^ b) & 0x80) != 0 && ((a ^ self.a) & 0x80) != 0
    }
    
    // MARK: - A,X,Y registers
    
    // MARK: Logical instructions
    
    /// CPX - Compare X Register
    private mutating func cpx(stepData: StepData) {
        let value = read(address: stepData.address)
        compare(firstValue: x, secondValue: value)
    }
    
    /// CPY - Compare Y Register
    private mutating func cpy(stepData: StepData) {
        let value = read(address: stepData.address)
        compare(firstValue: y, secondValue: value)
    }
    
    // MARK: Increment and decrement operations
    
    /// DEX - Decrement X Register
    private mutating func dex() {
        x &-= 1
        setZN(value: x)
    }
    
    /// DEY - Decrement Y Register
    private mutating func dey() {
        y &-= 1
        setZN(value: y)
    }
    
    /// INX - Increment X Register
    private mutating func inx() {
        x &+= 1
        setZN(value: x)
    }
    
    /// INY - Increment Y Register
    private mutating func iny() {
        y &+= 1
        setZN(value: y)
    }
    
    // MARK: Load instructions
    
    /// LDA - Load accumulator
    private mutating func lda(stepData: StepData) {
        a = read(address: stepData.address)
        setZN(value: a)
    }
    
    /// LDX - Load X Register
    private mutating func ldx(stepData: StepData) {
        x = read(address: stepData.address)
        setZN(value: x)
    }
    
    /// LDY - Load Y Register
    private mutating func ldy(stepData: StepData) {
        y = read(address: stepData.address)
        setZN(value: y)
    }
    
    // MARK: Store instructions
    
    /// STA - Store Accumulator
    private mutating func sta(stepData: StepData) {
        write(address: stepData.address, value: a)
    }
    
    /// STX - Store X Register
    private mutating func stx(stepData: StepData) {
        write(address: stepData.address, value: x)
    }
    
    /// STY - Store Y Register
    private mutating func sty(stepData: StepData) {
        write(address: stepData.address, value: y)
    }
    
    // MARK: Transfer instructions
    
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
    
    private mutating func tsx() {
        x = sp
        setZN(value: x)
    }
    
    private mutating func txa() {
        a = x
        setZN(value: a)
    }
    
    private mutating func txs() {
        sp = x
    }
    
    private mutating func tya() {
        a = y
        setZN(value: a)
    }
    
    // MARK: - status register
    
    /// CLC - Clear Carry Flag
    private mutating func clc() {
        c = false
    }
    
    /// CLD - Clear Decimal Mode
    private mutating func cld() {
        d = false
    }
    
    /// CLI - Clear Interrupt Disable
    private mutating func  cli() {
        i = false
    }
    
    /// CLV - Clear Overflow Flag
    private mutating func  clv() {
        v = false
    }
    
    /// SEC - Set Carry Flag
    private mutating func sec() {
        c = true
    }
    
    /// SED - Set Decimal Flag
    private mutating func sed() {
        d = true
    }
    
    /// SEI - Set Interrupt Disable
    private mutating func sei() {
        i = true
    }
    
    // MARK: - stack related
    
    // MARK: - control flow
    
    // MARK: - interrupts
}

extension CPU {
    
    /// execute instruction and returns number of steps
    mutating func step() -> Int {
        
        // TODO: Don't foreget to finish this thing
        
        let opcode = read(address: pc)
        let instructionInfo = getInstrutcionTable()[Int(opcode)]
        let mode: AddressingMode = .absolute // TODO: <- get addressing mode from instruction info
        let address: UInt16 = 0 // TODO: <- get correct address depending on addressing mode
        let stepData = StepData(address: address, mode: mode, pc: self.pc)
        
        // TODO: Execute instruction
        
        // TODO: create counter
        
        return 0
    }
}

extension CPU {
    
    func getInstrutcionTable() -> [InstructionData] {
        // TODO: create instructions table
        return [
            
        ]
    }
}

// MARK: - Data Models

// TODO: separate from this file
enum AddressingMode: UInt8 {
    case absolute, absoluteXIndexed, absoluteYIndexed, accumulator, immediate, implied, xIndexedIndirect, indirect, indirectYIndexed, relative, zeropage, zeroPageXIndexed, zeroPageYIndexed
}

struct StepData {
    
    /// memory address
    let address: UInt16
    
    /// addressing mode
    let mode: AddressingMode
    
    /// program counter
    let pc: UInt16
}

// TODO: create instruction data model

struct InstructionData {
    
}
