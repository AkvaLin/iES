//
//  CPU.swift
//  iES
//
//  Created by Никита Пивоваров on 01.06.2024.
//

import Foundation

final class CPU {
    
    static let frequency: Int = 1789773
    var ppu: PPU
    var apu: APU
    var isStopped: Bool = false
    var controllers: [Controller]
    
    init(ppu: PPU, apu: APU, controllers: [Controller], state: CPUState? = nil) {
        self.ppu = ppu
        self.apu = apu
        self.controllers = controllers
        if let state {
            ram = state.ram
            a = state.a
            x = state.x
            y = state.y
            pc = state.pc
            sp = state.sp
            cycles = state.cycles
            stall = state.stall
            set(flags: state.flags)
        }
    }
    
    var cpuState: CPUState
    {
        return CPUState.init(ram: self.ram, a: self.a, x: self.x, y: self.y, pc: self.pc, sp: self.sp, cycles: self.cycles, flags: self.flags(), interrupt: self.interrupt.rawValue, stall: self.stall)
    }
    
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
    
    /// interrupt type to perform
    private var interrupt: Interrupt = .none
    
    /// number of cycles to stall
    private var stall: UInt64 = 0
}

// MARK: - Flag operations

extension CPU {
    /// returns a UInt8 with flag bits arranged as c,z,i,d,b,u,v,n
    private func flags() -> UInt8 {
        let flagByte: UInt8 = UInt8.init(fromLittleEndianBitArray: [self.c, self.z, self.i, self.d, self.b, self.u, self.v, self.n])
        return flagByte
    }
    
    /// sets processor status with bits arranged as c,z,i,d,b,u,v,n
    private func set(flags: UInt8) {
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
    private func setZ(value: UInt8) {
        self.z = (value == 0) ? true : false
    }
    
    /// sets the negative flag if the argument is negative
    private func setN(value: UInt8) {
        self.n = (value & 0x80 != 0) ? true : false
    }
    
    private func setZN(value: UInt8) {
        setZ(value: value)
        setN(value: value)
    }
    
    /**
     compares two values and sets zero, negative and carry flags
     - parameter firstValue: the main value that will be compared
     - parameter secondValue: the value to be compared with
     */
    private func compare(firstValue: UInt8, secondValue: UInt8)
    {
        self.setZN(value: firstValue &- secondValue)
        self.c = firstValue >= secondValue ? true : false
    }
}

// MARK: - Memory
extension CPU {
    
    private func read(address: UInt16) -> UInt8
    {
        switch address {
        case 0x0000 ..< 0x2000:
            return self.ram[Int(address % 0x0800)]
        case 0x2000 ..< 0x4000:
            return self.ppu.readRegister(address: 0x2000 + (address % 8))
        case 0x4014:
            return self.ppu.readRegister(address: address)
        case 0x4015:
            return apu.readRegister(address: address)
        case 0x4016:
            return self.controllers[0].read()
        case 0x4017:
            return self.controllers[1].read()
        case 0x4000 ..< 0x5000:
            // TODO: I/O registers
            return 0
        case 0x5000 ... 0xFFFF:
            return self.ppu.mapper.cpuRead(address: address)
        default:
            return 0
        }
    }
    
    /// check whether two addresses reside on different pages
    private func isDifferentpages(address1: UInt16, address2: UInt16) -> Bool {
        return address1 & 0xFF00 != address2 & 0xFF00
    }
    
    private func write(address: UInt16, value: UInt8) {
        switch address {
        case 0x0000 ..< 0x2000:
            ram[Int(address % 0x0800)] = value
        case 0x2000 ..< 0x4000:
            self.ppu.writeRegister(address: 0x2000 + (address % 8), value: value)
        case 0x4000..<0x4014:
            self.apu.writeRegister(address: address, value: value)
        case 0x4014:
            let startIndex: Int = Int(UInt16(value) << 8)
            self.ppu.writeOAMDMA(oamDMA: [UInt8](self.ram[startIndex ..< startIndex + 256]))
            self.stall += (self.cycles % 2 == 0) ? 513 : 514
        case 0x4015:
            self.apu.writeRegister(address: address, value: value)
        case 0x4016:
            self.controllers[0].write(value: value)
            self.controllers[1].write(value: value)
        case 0x4017:
            self.apu.writeRegister(address: address, value: value)
        case 0x4000 ..< 0x5000:
            // TODO: I/O registers
            break
        case 0x5000 ... 0xFFFF:
            self.ppu.mapper.cpuWrite(address: address, value: value)
        default:
            break
        }
    }
    
    /// read two bytes and return a double-word value
    private func read16(address: UInt16) -> UInt16 {
        let low = UInt16(read(address: address))
        let high = UInt16(read(address: address &+ 1))
        
        return (high << 8) | low
    }
    
    /// impements 6502 bug in reading
    private func read16bug(address: UInt16) -> UInt16 {
        let b: UInt16 = (address & 0xFF00) | UInt16((address % 256) &+ 1)
        let low = read(address: address)
        let high = read(address: b)
        
        return (UInt16(high) << 8) | UInt16(low)
    }
}

// MARK: - Stack

extension CPU {
    
    /// push a byte to the stack
    private func push(value: UInt8) {
        write(address: 0x100 | UInt16(sp), value: value)
        sp &-= 1
    }
    
    /// pop a byte from the stack
    private func pop() -> UInt8 {
        sp &+= 1
        return read(address: 0x100 | UInt16(sp))
    }
    
    /// push two bytes to the stack
    private func push16(value: UInt16) {
        let low = UInt8(value & 0xFF)
        let high = UInt8(value >> 8)
        
        push(value: high)
        push(value: low)
    }
    
    /// pop two bytes from the stack
    private func pop16() -> UInt16 {
        let low = UInt16(pop())
        let high = UInt16(pop())
        
        return (high << 8) | low
    }
}

// MARK: Interrupt Operations
extension CPU {
    /// causes a non-maskable interrupt to occur on the next cycle
    func triggerNMI()
    {
        self.interrupt = .nmi
    }
    
    /// causes an IRQ interrupt to occur on the next cycle, if the interrupt disable flag is not set
    func triggerIRQ()
    {
        if self.i == false
        {
            self.interrupt = .irq
        }
    }
}

// MARK: - Timing

extension CPU {
    private func addCycles(stepData: StepData) {
        cycles &+= 1
        if isDifferentpages(address1: pc, address2: stepData.address) {
            cycles &+= 1
        }
    }
    
    /// NMI - Non-Maskable Interrupt
    private func nmi()
    {
        self.push16(value: self.pc)
        php(stepData: .init(address: 0, mode: .implied, pc: 0))
        self.pc = self.read16(address: 0xFFFA)
        self.i = true
        self.cycles &+= 7
    }
    
    /// IRQ - IRQ Interrupt
    /// IRQ - IRQ Interrupt
    private func irq()
    {
        self.push16(value: self.pc)
        php(stepData: .init(address: 0, mode: .implied, pc: 0))
        self.pc = self.read16(address: 0xFFFE)
        self.i = true
        self.cycles &+= 7
    }
}

// MARK: - 6502 functions
extension CPU {
    
    /// NOP - No Operation
    private func nop(stepData: StepData) { }
    
    // MARK: - arithmetic & logic
    
    /// ADC - Add with Carry
    private func adc(stepData: StepData) {
        let a = a
        let b = read(address: stepData.address)
        let c: UInt8 = c ? 1 : 0
        self.a = a &+ b &+ c
        self.setZN(value: self.a)
        self.c = Int(a) + Int(b) + Int(c) > 0xFF
        self.v = ((a ^ b) & 0x80) == 0 && ((a ^ self.a) & 0x80) != 0
    }
    
    /// AND - Logical AND
    private func and(stepData: StepData) {
        a = a & read(address: stepData.address)
        setZN(value: a)
    }
    
    /// ASL - Arithmetic Shift Left
    private func asl(stepData: StepData) {
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
    private func bit(stepData: StepData) {
        let value = read(address: stepData.address)
        v = ((value >> 6) & 1) == 1
        setZ(value: value & a)
        setN(value: value)
    }
    
    /// CMP - Compare
    private func cmp(stepData: StepData) {
        let value = read(address: stepData.address)
        compare(firstValue: a, secondValue: value)
    }
    
    /// DEC - Decrement Memory
    private func dec(stepData: StepData) {
        let value = read(address: stepData.address) &- 1
        write(address: stepData.address, value: value)
        setZN(value: value)
    }
    
    /// EOR - Exclusive OR
    private func eor(stepData: StepData) {
        a = a ^ read(address: stepData.address)
        setZN(value: a)
    }
    
    /// LSR - Logical Shift Right
    private func lsr(stepData: StepData) {
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
    private func ora(stepData: StepData) {
        a = a | read(address: stepData.address)
        setZN(value: a)
    }
    
    /// ROL - Rotate Left
    private func rol(stepData: StepData) {
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
    private func ror(stepData: StepData) {
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
    private func sbc(stepData: StepData) {
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
    private func cpx(stepData: StepData) {
        let value = read(address: stepData.address)
        compare(firstValue: x, secondValue: value)
    }
    
    /// CPY - Compare Y Register
    private func cpy(stepData: StepData) {
        let value = read(address: stepData.address)
        compare(firstValue: y, secondValue: value)
    }
    
    // MARK: Increment and decrement operations
    
    /// DEX - Decrement X Register
    private func dex(stepData: StepData) {
        x &-= 1
        setZN(value: x)
    }
    
    /// DEY - Decrement Y Register
    private func dey(stepData: StepData) {
        y &-= 1
        setZN(value: y)
    }
    
    /// INC - Increment Memory
    private func inc(stepData: StepData)
    {
        let value: UInt8 = read(address: stepData.address) &+ 1 // wrap if needed
        write(address: stepData.address, value: value)
        setZN(value: value)
    }
    
    /// INX - Increment X Register
    private func inx(stepData: StepData) {
        x &+= 1
        setZN(value: x)
    }
    
    /// INY - Increment Y Register
    private func iny(stepData: StepData) {
        y &+= 1
        setZN(value: y)
    }
    
    // MARK: Load instructions
    
    /// LDA - Load accumulator
    private func lda(stepData: StepData) {
        a = read(address: stepData.address)
        setZN(value: a)
    }
    
    /// LDX - Load X Register
    private func ldx(stepData: StepData) {
        x = read(address: stepData.address)
        setZN(value: x)
    }
    
    /// LDY - Load Y Register
    private func ldy(stepData: StepData) {
        y = read(address: stepData.address)
        setZN(value: y)
    }
    
    // MARK: Store instructions
    
    /// STA - Store Accumulator
    private func sta(stepData: StepData) {
        write(address: stepData.address, value: a)
    }
    
    /// STX - Store X Register
    private func stx(stepData: StepData) {
        write(address: stepData.address, value: x)
    }
    
    /// STY - Store Y Register
    private func sty(stepData: StepData) {
        write(address: stepData.address, value: y)
    }
    
    // MARK: Transfer instructions
    
    /// TAX - Transfer Accumulator to X
    private func tax(stepData: StepData) {
        x = a
        setZN(value: x)
    }
    
    /// TAY - Transfer Accumulator to Y
    private func tay(stepData: StepData) {
        y = a
        setZN(value: y)
    }
    
    private func tsx(stepData: StepData) {
        x = sp
        setZN(value: x)
    }
    
    private func txa(stepData: StepData) {
        a = x
        setZN(value: a)
    }
    
    private func txs(stepData: StepData) {
        sp = x
    }
    
    private func tya(stepData: StepData) {
        a = y
        setZN(value: a)
    }
    
    // MARK: - status register
    
    /// CLC - Clear Carry Flag
    private func clc(stepData: StepData) {
        c = false
    }
    
    /// CLD - Clear Decimal Mode
    private func cld(stepData: StepData) {
        d = false
    }
    
    /// CLI - Clear Interrupt Disable
    private func  cli(stepData: StepData) {
        i = false
    }
    
    /// CLV - Clear Overflow Flag
    private func  clv(stepData: StepData) {
        v = false
    }
    
    /// SEC - Set Carry Flag
    private func sec(stepData: StepData) {
        c = true
    }
    
    /// SED - Set Decimal Flag
    private func sed(stepData: StepData) {
        d = true
    }
    
    /// SEI - Set Interrupt Disable
    private func sei(stepData: StepData) {
        i = true
    }
    
    // MARK: - stack related
    
    /// PHA - Push Accumulator
    private func pha(stepData: StepData) {
        push(value: a)
    }
    
    /// PHP - Push Processor Status
    private func php(stepData: StepData) {
        push(value: flags() | 0x10)
    }
    
    /// PLA - Pull Accumulator
    private func pla(stepData: StepData) {
        a = pop()
        setZN(value: a)
    }
    
    /// PLP - Pull Processor Status
    private func plp(stepData: StepData) {
        set(flags: (pop() & 0xEF) | 0x20)
    }
    
    // MARK: - control flow
    
    /// BCC - Branch if Carry Clear
    private func bcc(stepData: StepData) {
        if !c {
            pc = stepData.address
            addCycles(stepData: stepData)
        }
    }
    
    /// BCS - Branch if Carry Set
    private func bcs(stepData: StepData) {
        if c {
            pc = stepData.address
            addCycles(stepData: stepData)
        }
    }
    
    /// BEQ - Branch if Equal
    private func beq(stepData: StepData) {
        if z {
            pc = stepData.address
            addCycles(stepData: stepData)
        }
    }
    
    /// BMI - Branch if Minus
    private func bmi(stepData: StepData) {
        if n
        {
            pc = stepData.address
            addCycles(stepData: stepData)
        }
    }
    
    /// BNE - Branch if Not Equal
    private func bne(stepData: StepData) {
        if !z {
            pc = stepData.address
            addCycles(stepData: stepData)
        }
    }
    
    /// BPL - Branch if Positive
    private func bpl(stepData: StepData) {
        if !n {
            pc = stepData.address
            addCycles(stepData: stepData)
        }
    }
    
    /// BVC - Branch if Overflow Clear
    private func bvc(stepData: StepData) {
        if !v {
            pc = stepData.address
            addCycles(stepData: stepData)
        }
    }
    
    /// BVS - Branch if Overflow Set
    private func bvs(stepData: StepData) {
        if v {
            pc = stepData.address
            addCycles(stepData: stepData)
        }
    }
    
    /// JMP - Jump
    private func jmp(stepData: StepData) {
        pc = stepData.address
    }
    
    /// JSR - Jump to Subroutine
    private func jsr(stepData: StepData) {
        push16(value: pc - 1)
        pc = stepData.address
    }
    
    /// RTS - Return from Subroutine
    private func rts(stepData: StepData) {
        pc = pop16() &+ 1
    }
    
    // MARK: - interrupts
    
    /// BRK - Force Interrupt
    private func brk(stepData: StepData) {
        push16(value: pc)
        php(stepData: stepData)
        sei(stepData: stepData)
        pc = read16(address: 0xFFFE)
    }
    
    /// RTI - Return from Interrupt
    private func rti(stepData: StepData) {
        set(flags:  (pop() & 0xEF) | 0x20)
        pc = pop16()
    }
}

// MARK: Illegal Instructions
extension CPU {
    private func ahx(stepData: StepData) {
        /*
         SHA (AHX, AXA)
         Stores A AND X AND (high-byte of addr. + 1) at addr.
         
         unstable: sometimes 'AND (H+1)' is dropped, page boundary crossings may not work (with the high-byte of the value used as the high-byte of the address)
         
         A AND X AND (H+1) -> M
         N    Z    C    I    D    V
         -    -    -    -    -    -
         addressing    assembler    opc    bytes    cycles
         absolut,Y    SHA oper,Y    9F     3        5      †
         (indirect),Y SHA (oper),Y  93     2        6      †
         */
        let value: UInt8 = a & x & read(address: stepData.address &+ 1)
        write(address: stepData.address, value: value)
    }
    
    private func alr(stepData: StepData) {
        /*
         ALR (ASR)
         AND oper + LSR
         
         A AND oper, 0 -> [76543210] -> C
         N    Z    C    I    D    V
         +    +    +    -    -    -
         addressing    assembler    opc    bytes    cycles
         immediate     ALR #oper    4B     2        2
         */
        c = false
        a = a & read(address: stepData.address)
        if a & 0x01 == 1
        {
            c = true
        }
        a >>= 1
        setZN(value: a)
    }
    
    private func anc(stepData: StepData) {
        /*
         ANC
         AND oper + set C as ASL
         
         A AND oper, bit(7) -> C
         N    Z    C    I    D    V
         +    +    +    -    -    -
         addressing    assembler    opc    bytes    cycles
         immediate    ANC #oper     0B     2        2
         */
        and(stepData: stepData)
        c = a & 0x80 == 0x80
    }
    
    private func arr(stepData: StepData) {
        /*
         ARR
         AND oper + ROR
         
         This operation involves the adder:
         V-flag is set according to (A AND oper) + oper
         The carry is not set, but bit 7 (sign) is exchanged with the carry
         
         A AND oper, C -> [76543210] -> C
         N    Z    C    I    D    V
         +    +    +    -    -    +
         addressing    assembler     opc    bytes    cycles
         immediate     ARR #oper     6B     2        2
         */
        let operandValue: UInt8 = read(address: stepData.address)
        a = ((a & operandValue) >> 1) | (c ? 0x80 : 0x00)
        c = a & 0x40 != 0
        v = ((c ? 0x01 : 0x00) ^ ((a >> 5) & 0x01)) != 0
        setZN(value: a)
    }
    
    private func sbx(stepData: StepData) {
        /*
         SBX (AXS, SAX)
         CMP and DEX at once, sets flags like CMP
         
         (A AND X) - oper -> X
         N    Z    C    I    D    V
         +    +    +    -    -    -
         addressing    assembler     opc    bytes    cycles
         immediate     SBX #oper     CB     2        2
         */
        let opValue: UInt8 = read(address: stepData.address)
        let value: UInt8 = (a & x) &- opValue
        c = a & x >= opValue
        x = value
        setZN(value: value)
    }
    
    private func dcp(stepData: StepData) {
        /*
         DCP (DCM)
         DEC oper + CMP oper
         
         M - 1 -> M, A - M
         N    Z    C    I    D    V
         +    +    +    -    -    -
         addressing    assembler    opc    bytes    cycles
         zeropage    DCP oper    C7    2    5
         zeropage,X    DCP oper,X    D7    2    6
         absolute    DCP oper    CF    3    6
         absolut,X    DCP oper,X    DF    3    7
         absolut,Y    DCP oper,Y    DB    3    7
         (indirect,X)    DCP (oper,X)    C3    2    8
         (indirect),Y    DCP (oper),Y    D3    2    8
         */
        dec(stepData: stepData)
        cmp(stepData: stepData)
    }
    
    private func isc(stepData: StepData) {
        /*
         ISC (ISB, INS)
         INC oper + SBC oper
         
         M + 1 -> M, A - M - C -> A
         N    Z    C    I    D    V
         +    +    +    -    -    +
         addressing    assembler     opc    bytes    cycles
         zeropage      ISC oper      E7     2    5
         zeropage,X    ISC oper,X    F7     2    6
         absolute      ISC oper      EF     3    6
         absolut,X     ISC oper,X    FF     3    7
         absolut,Y     ISC oper,Y    FB     3    7
         (indirect,X)  ISC (oper,X)  E3     2    8
         (indirect),Y  ISC (oper),Y  F3     2    8
         */
        inc(stepData: stepData)
        sbc(stepData: stepData)
    }
    
    private func kil(stepData: StepData) {
        isStopped = true
        pc &-= 1
        cycles &+= 0xFF
    }
    
    private func las(stepData: StepData) {
        /*
         LAS (LAR)
         LDA/TSX oper
         
         M AND SP -> A, X, SP
         N    Z    C    I    D    V
         +    +    -    -    -    -
         addressing    assembler    opc    bytes    cycles
         absolut,Y    LAS oper,Y    BB    3    4*
         */
        lda(stepData: stepData)
        tsx(stepData: stepData)
    }
    
    private func lax(stepData: StepData) {
        /*
         LAX
         LDA oper + LDX oper
         
         M -> A -> X
         N    Z    C    I    D    V
         +    +    -    -    -    -
         addressing    assembler     opc    bytes    cycles
         zeropage      LAX oper      A7     2        3
         zeropage,Y    LAX oper,Y    B7     2        4
         absolute      LAX oper      AF     3        4
         absolut,Y     LAX oper,Y    BF     3        4*
         (indirect,X)  LAX (oper,X)  A3     2        6
         (indirect),Y  LAX (oper),Y  B3     2        5*
         */
        lda(stepData: stepData)
        ldx(stepData: stepData)
    }
    
    private func rla(stepData: StepData) {
        /*
         RLA
         ROL oper + AND oper
         
         M = C <- [76543210] <- C, A AND M -> A
         N    Z    C    I    D    V
         +    +    +    -    -    -
         addressing    assembler    opc    bytes    cycles
         zeropage      RLA oper     27     2        5
         zeropage,X    RLA oper,X   37     2        6
         absolute      RLA oper     2F     3        6
         absolut,X     RLA oper,X   3F     3        7
         absolut,Y     RLA oper,Y   3B     3        7
         (indirect,X)  RLA (oper,X) 23     2        8
         (indirect),Y  RLA (oper),Y 33     2        8
         */
        rol(stepData: stepData)
        and(stepData: stepData)
    }
    
    private func rra(stepData: StepData) {
        /*
         RRA
         ROR oper + ADC oper
         
         M = C -> [76543210] -> C, A + M + C -> A, C
         N    Z    C    I    D    V
         +    +    +    -    -    +
         addressing    assembler     opc    bytes    cycles
         zeropage      RRA oper      67     2        5
         zeropage,X    RRA oper,X    77     2        6
         absolute      RRA oper      6F     3        6
         absolut,X     RRA oper,X    7F     3        7
         absolut,Y     RRA oper,Y    7B     3        7
         (indirect,X)  RRA (oper,X)  63     2        8
         (indirect),Y  RRA (oper),Y  73     2        8
         */
        ror(stepData: stepData)
        adc(stepData: stepData)
    }
    
    private func sax(stepData: StepData) {
        /*
         SAX (AXS, AAX)
         A and X are put on the bus at the same time (resulting effectively in an AND operation) and stored in M
         
         A AND X -> M
         N    Z    C    I    D    V
         -    -    -    -    -    -
         addressing    assembler     opc    bytes    cycles
         zeropage      SAX oper      87     2        3
         zeropage,Y    SAX oper,Y    97     2        4
         absolute      SAX oper      8F     3        4
         (indirect,X)  SAX (oper,X)  83     2        6
         */
        let value = a & x
        write(address: stepData.address, value: value)
    }
    
    private func shx(stepData: StepData) {
        /*
         SHX (A11, SXA, XAS)
         Stores X AND (high-byte of addr. + 1) at addr.
         
         unstable: sometimes 'AND (H+1)' is dropped, page boundary crossings may not work (with the high-byte of the value used as the high-byte of the address)
         
         X AND (H+1) -> M
         N    Z    C    I    D    V
         -    -    -    -    -    -
         addressing    assembler    opc    bytes    cycles
         absolut,Y    SHX oper,Y    9E    3    5      †
         */
        let newAddr = ((UInt16(x) & ((stepData.address >> 8) &+ 1)) << 8) | (stepData.address & 0xFF)
        write(address: newAddr, value: UInt8(newAddr >> 8))
    }
    
    private func shy(stepData: StepData) {
        /*
         SHY (A11, SYA, SAY)
         Stores Y AND (high-byte of addr. + 1) at addr.
         
         unstable: sometimes 'AND (H+1)' is dropped, page boundary crossings may not work (with the high-byte of the value used as the high-byte of the address)
         
         Y AND (H+1) -> M
         N    Z    C    I    D    V
         -    -    -    -    -    -
         addressing    assembler    opc    bytes    cycles
         absolut,X    SHY oper,X    9C    3    5      †
         */
        let newAddr = ((UInt16(y) & ((stepData.address >> 8) &+ 1)) << 8) | (stepData.address & 0xFF)
        write(address: newAddr, value: UInt8(newAddr >> 8))
    }
    
    private func slo(stepData: StepData) {
        /*
         SLO (ASO)
         ASL oper + ORA oper
         
         M = C <- [76543210] <- 0, A OR M -> A
         N    Z    C    I    D    V
         +    +    +    -    -    -
         addressing    assembler    opc    bytes    cycles
         zeropage      SLO oper      07    2        5
         zeropage,X    SLO oper,X    17    2        6
         absolute      SLO oper      0F    3        6
         absolut,X     SLO oper,X    1F    3        7
         absolut,Y     SLO oper,Y    1B    3        7
         (indirect,X)  SLO (oper,X)  03    2        8
         (indirect),Y  SLO (oper),Y  13    2        8
         */
        asl(stepData: stepData)
        ora(stepData: stepData)
    }
    
    private func sre(stepData: StepData) {
        /*
         SRE (LSE)
         LSR oper + EOR oper
         
         M = 0 -> [76543210] -> C, A EOR M -> A
         N    Z    C    I    D    V
         +    +    +    -    -    -
         addressing     assembler     opc    bytes    cycles
         zeropage       SRE oper      47     2        5
         zeropage,X     SRE oper,X    57     2        6
         absolute       SRE oper      4F     3        6
         absolut,X      SRE oper,X    5F     3        7
         absolut,Y      SRE oper,Y    5B     3        7
         (indirect,X)   SRE (oper,X)  43     2        8
         (indirect),Y   SRE (oper),Y  53     2        8
         */
        lsr(stepData: stepData)
        eor(stepData: stepData)
    }
    
    private func tas(stepData: StepData) {
        /*
         TAS (XAS, SHS)
         Puts A AND X in SP and stores A AND X AND (high-byte of addr. + 1) at addr.
         
         unstable: sometimes 'AND (H+1)' is dropped, page boundary crossings may not work (with the high-byte of the value used as the high-byte of the address)
         
         A AND X -> SP, A AND X AND (H+1) -> M
         N    Z    C    I    D    V
         -    -    -    -    -    -
         addressing    assembler    opc    bytes    cycles
         absolut,Y    TAS oper,Y    9B     3        5†
         */
        let value1: UInt8 = a & x
        let value2: UInt8 = value1 & read(address: stepData.address &+ 1)
        sp = value1
        write(address: stepData.address, value: value2)
    }
    
    private func xaa(stepData: StepData) {
        /*
         ANE (XAA)
         * AND X + AND oper
         
         Highly unstable, do not use.
         A base value in A is determined based on the contets of A and a constant, which may be typically $00, $ff, $ee, etc. The value of this constant depends on temerature, the chip series, and maybe other factors, as well.
         In order to eliminate these uncertaincies from the equation, use either 0 as the operand or a value of $FF in the accumulator.
         
         (A OR CONST) AND X AND oper -> A
         N    Z    C    I    D    V
         +    +    -    -    -    -
         addressing    assembler    opc    bytes    cycles
         immediate     ANE #oper     8B    2        2††
         */
        a = a & x
        setZN(value: a)
    }
}

// MARK: - Reset

extension CPU {
    /// Reset resets the CPU to its initial powerup state
    func reset() {
        pc = self.read16(address: 0xFFFC)
        sp = 0xFD
        set(flags: 0x24)
        
        ppu.reset()
    }
}

extension CPU {
    
    /// execute instruction and returns number of steps
    func step() -> Int {
        let numCPUCyclesThisStep: Int
        
        guard self.stall == 0 else {
            numCPUCyclesThisStep = 1
            stall -= 1
            stepOthers(for: numCPUCyclesThisStep)
            return numCPUCyclesThisStep
        }
        
        let oldCycles = cycles
        
        switch self.interrupt {
        case .nmi:
            nmi()
        case .irq:
            irq()
            isStopped = false
        default:
            break
        }
        self.interrupt = .none
        
        let opcode = read(address: pc)
        let instructionInfo = getInstrutcionTable()[Int(opcode)]
        let mode: AddressingMode = instructionInfo.mode
        let address: UInt16
        let pageCrossed: Bool
        
        switch mode {
        case .absolute:
            address = read16(address: pc &+ 1)
            pageCrossed = false
        case .absoluteXIndexed:
            address = read16(address: pc &+ 1) &+ UInt16(x)
            pageCrossed = isDifferentpages(address1: address &- UInt16(x), address2: address)
        case .absoluteYIndexed:
            address = read16(address: pc &+ 1) &+ UInt16(y)
            pageCrossed = isDifferentpages(address1: address &- UInt16(y), address2: address)
        case .accumulator:
            address = 0
            pageCrossed = false
        case .immediate:
            address = pc &+ 1
            pageCrossed = false
        case .implied:
            address = 0
            pageCrossed = false
        case .xIndexedIndirect:
            let zero: UInt8 = read(address: pc &+ 1) &+ x
            
            if zero == 0xFF {
                address = UInt16(read(address: 0x00FF)) | (UInt16(read(address: 0x0000)) << 8)
            } else {
                address = read16bug(address: UInt16(zero))
            }
            
            pageCrossed = false
        case .indirect:
            let vector = read16(address: pc &+ 1)
            if vector & 0x00FF == 0x00FF {
                let lo = read(address: vector)
                let hi = read(address: vector &- 0x00FF)
                address = UInt16(lo) | (UInt16(hi) << 8)
            } else {
                address = read16bug(address: vector)
            }
            pageCrossed = false
        case .indirectYIndexed:
            let zero: UInt8 = read(address: pc &+ 1)
            
            if zero == 0xFF {
                address = UInt16(read(address: 0x00FF)) | (UInt16(read(address: 0x0000)) << 8) &+ UInt16(y)
            }
            else
            {
                address = read16bug(address: UInt16(zero)) &+ UInt16(y)
            }
            
            pageCrossed = isDifferentpages(address1: address &- UInt16(y), address2: address)
        case .relative:
            let offset = UInt16(read(address: pc &+ 1))
            if offset < 0x80 {
                address = pc &+ 2 &+ offset
            } else {
                address = pc &+ 2 &+ offset &- 0x100
            }
            pageCrossed = false
        case .zeropage:
            address = UInt16(read(address: pc &+ 1))
            pageCrossed = false
        case .zeroPageXIndexed:
            address = UInt16(read(address: pc &+ 1) &+ x) & 0xff
            pageCrossed = false
        case .zeroPageYIndexed:
            address = UInt16(read(address: pc &+ 1) &+ y) & 0xff
            pageCrossed = false
        }
        
        self.pc &+= UInt16(instructionInfo.bytes)
        self.cycles &+= UInt64(instructionInfo.cycles)
        if pageCrossed {
            self.cycles &+= UInt64(instructionInfo.pageCycles)
        }
        
        let stepData = StepData(address: address, mode: mode, pc: self.pc)
        instructionInfo.instruction(stepData)
        
        numCPUCyclesThisStep = Int(cycles - oldCycles)
        
        stepOthers(for: numCPUCyclesThisStep)
        
        return numCPUCyclesThisStep
    }
    
    private func stepOthers(for numCPUCycles: Int) {
        // PPU step
        for _ in 0 ..< numCPUCycles * 3 {
            let ppuStepResults: PPUStepResults = self.ppu.step()
            if let safeRequestedInterrupt: Interrupt = ppuStepResults.requestedCPUInterrupt {
                switch safeRequestedInterrupt {
                case .irq: self.triggerIRQ()
                case .nmi: self.triggerNMI()
                case .none: self.interrupt = .none
                }
            }
        }
        // APU step
        
        for _ in 0 ..< numCPUCycles {
            let dmcCurrentAddressValue: UInt8 = self.read(address: self.apu.dmcCurrentAddress)
            let apuStepResults: APUStepResults = self.apu.step(dmcCurrentAddressValue: dmcCurrentAddressValue)
            self.stall += apuStepResults.numCPUStallCycles
            if apuStepResults.shouldTriggerIRQOnCPU {
                self.triggerIRQ()
            }
        }
    }
}

extension CPU {
    
    /// reuturns all combinations of instructions
    private func getInstrutcionTable() -> [InstructionData] {
        return [
            InstructionData(instruction: brk, mode: .implied,          cycles: 7, pageCycles: 0, bytes: 2), // 00
            InstructionData(instruction: ora, mode: .xIndexedIndirect, cycles: 6, pageCycles: 0, bytes: 2), // 01
            InstructionData(instruction: kil, mode: .implied,          cycles: 1, pageCycles: 0, bytes: 1), // 02
            InstructionData(instruction: slo, mode: .xIndexedIndirect, cycles: 8, pageCycles: 0, bytes: 2), // 03
            InstructionData(instruction: nop, mode: .zeropage,         cycles: 3, pageCycles: 0, bytes: 2), // 04
            InstructionData(instruction: ora, mode: .zeropage,         cycles: 3, pageCycles: 0, bytes: 2), // 05
            InstructionData(instruction: asl, mode: .zeropage,         cycles: 5, pageCycles: 0, bytes: 2), // 06
            InstructionData(instruction: slo, mode: .zeropage,         cycles: 5, pageCycles: 0, bytes: 2), // 07
            InstructionData(instruction: php, mode: .implied,          cycles: 3, pageCycles: 0, bytes: 1), // 08
            InstructionData(instruction: ora, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2), // 09
            InstructionData(instruction: asl, mode: .accumulator,      cycles: 2, pageCycles: 0, bytes: 1), // 0A
            InstructionData(instruction: anc, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2), // 0B
            InstructionData(instruction: nop, mode: .absolute,         cycles: 4, pageCycles: 0, bytes: 3), // 0C
            InstructionData(instruction: ora, mode: .absolute,         cycles: 4, pageCycles: 0, bytes: 3), // 0D
            InstructionData(instruction: asl, mode: .absolute,         cycles: 6, pageCycles: 0, bytes: 3), // 0E
            InstructionData(instruction: slo, mode: .absolute,         cycles: 6, pageCycles: 0, bytes: 3), // 0F
            InstructionData(instruction: bpl, mode: .relative,         cycles: 2, pageCycles: 1, bytes: 2), // 10
            InstructionData(instruction: ora, mode: .indirectYIndexed, cycles: 5, pageCycles: 1, bytes: 2), // 11
            InstructionData(instruction: kil, mode: .implied,          cycles: 1, pageCycles: 0, bytes: 1), // 12
            InstructionData(instruction: slo, mode: .indirectYIndexed, cycles: 8, pageCycles: 0, bytes: 2), // 13
            InstructionData(instruction: nop, mode: .zeroPageXIndexed, cycles: 4, pageCycles: 0, bytes: 2), // 14
            InstructionData(instruction: ora, mode: .zeroPageXIndexed, cycles: 4, pageCycles: 0, bytes: 2), // 15
            InstructionData(instruction: asl, mode: .zeroPageXIndexed, cycles: 6, pageCycles: 0, bytes: 2), // 16
            InstructionData(instruction: slo, mode: .zeroPageXIndexed, cycles: 6, pageCycles: 0, bytes: 2), // 17
            InstructionData(instruction: clc, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1), // 18
            InstructionData(instruction: ora, mode: .absoluteYIndexed, cycles: 4, pageCycles: 1, bytes: 3), // 19
            InstructionData(instruction: nop, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1), // 1A
            InstructionData(instruction: slo, mode: .absoluteYIndexed, cycles: 7, pageCycles: 0, bytes: 3), // 1B
            InstructionData(instruction: nop, mode: .absoluteXIndexed, cycles: 4, pageCycles: 1, bytes: 3), // 1C
            InstructionData(instruction: ora, mode: .absoluteXIndexed, cycles: 4, pageCycles: 1, bytes: 3), // 1D
            InstructionData(instruction: asl, mode: .absoluteXIndexed, cycles: 7, pageCycles: 0, bytes: 3), // 1E
            InstructionData(instruction: slo, mode: .absoluteXIndexed, cycles: 7, pageCycles: 0, bytes: 3), // 1F
            InstructionData(instruction: jsr, mode: .absolute,         cycles: 6, pageCycles: 0, bytes: 3), // 20
            InstructionData(instruction: and, mode: .xIndexedIndirect, cycles: 6, pageCycles: 0, bytes: 2), // 21
            InstructionData(instruction: kil, mode: .implied,          cycles: 1, pageCycles: 0, bytes: 1), // 22
            InstructionData(instruction: rla, mode: .xIndexedIndirect, cycles: 8, pageCycles: 0, bytes: 2), // 23
            InstructionData(instruction: bit, mode: .zeropage,         cycles: 3, pageCycles: 0, bytes: 2), // 24
            InstructionData(instruction: and, mode: .zeropage,         cycles: 3, pageCycles: 0, bytes: 2), // 25
            InstructionData(instruction: rol, mode: .zeropage,         cycles: 5, pageCycles: 0, bytes: 2), // 26
            InstructionData(instruction: rla, mode: .zeropage,         cycles: 5, pageCycles: 0, bytes: 2), // 27
            InstructionData(instruction: plp, mode: .implied,          cycles: 4, pageCycles: 0, bytes: 1), // 28
            InstructionData(instruction: and, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2), // 29
            InstructionData(instruction: rol, mode: .accumulator,      cycles: 2, pageCycles: 0, bytes: 1), // 2A
            InstructionData(instruction: anc, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2), // 2B
            InstructionData(instruction: bit, mode: .absolute,         cycles: 4, pageCycles: 0, bytes: 3), // 2C
            InstructionData(instruction: and, mode: .absolute,         cycles: 4, pageCycles: 0, bytes: 3), // 2D
            InstructionData(instruction: rol, mode: .absolute,         cycles: 6, pageCycles: 0, bytes: 3), // 2E
            InstructionData(instruction: rla, mode: .absolute,         cycles: 6, pageCycles: 0, bytes: 3), // 2F
            InstructionData(instruction: bmi, mode: .relative,         cycles: 2, pageCycles: 1, bytes: 2), // 30
            InstructionData(instruction: and, mode: .indirectYIndexed, cycles: 5, pageCycles: 1, bytes: 2), // 31
            InstructionData(instruction: kil, mode: .implied,          cycles: 1, pageCycles: 0, bytes: 1), // 32
            InstructionData(instruction: rla, mode: .indirectYIndexed, cycles: 8, pageCycles: 0, bytes: 2), // 33
            InstructionData(instruction: nop, mode: .zeroPageXIndexed, cycles: 4, pageCycles: 0, bytes: 2), // 34
            InstructionData(instruction: and, mode: .zeroPageXIndexed, cycles: 4, pageCycles: 0, bytes: 2), // 35
            InstructionData(instruction: rol, mode: .zeroPageXIndexed, cycles: 6, pageCycles: 0, bytes: 2), // 36
            InstructionData(instruction: rla, mode: .zeroPageXIndexed, cycles: 6, pageCycles: 0, bytes: 2), // 37
            InstructionData(instruction: sec, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1), // 38
            InstructionData(instruction: and, mode: .absoluteYIndexed, cycles: 4, pageCycles: 1, bytes: 3), // 39
            InstructionData(instruction: nop, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1), // 3A
            InstructionData(instruction: rla, mode: .absoluteYIndexed, cycles: 7, pageCycles: 0, bytes: 3), // 3B
            InstructionData(instruction: nop, mode: .absoluteXIndexed, cycles: 4, pageCycles: 1, bytes: 3), // 3C
            InstructionData(instruction: and, mode: .absoluteXIndexed, cycles: 4, pageCycles: 1, bytes: 3), // 3D
            InstructionData(instruction: rol, mode: .absoluteXIndexed, cycles: 7, pageCycles: 0, bytes: 3), // 3E
            InstructionData(instruction: rla, mode: .absoluteXIndexed, cycles: 7, pageCycles: 0, bytes: 3), // 3F
            InstructionData(instruction: rti, mode: .implied,          cycles: 6, pageCycles: 0, bytes: 1), // 40
            InstructionData(instruction: eor, mode: .xIndexedIndirect, cycles: 6, pageCycles: 0, bytes: 2), // 41
            InstructionData(instruction: kil, mode: .implied,          cycles: 1, pageCycles: 0, bytes: 1), // 42
            InstructionData(instruction: sre, mode: .xIndexedIndirect, cycles: 8, pageCycles: 0, bytes: 2), // 43
            InstructionData(instruction: nop, mode: .zeropage,         cycles: 3, pageCycles: 0, bytes: 2), // 44
            InstructionData(instruction: eor, mode: .zeropage,         cycles: 3, pageCycles: 0, bytes: 2), // 45
            InstructionData(instruction: lsr, mode: .zeropage,         cycles: 5, pageCycles: 0, bytes: 2), // 46
            InstructionData(instruction: sre, mode: .zeropage,         cycles: 5, pageCycles: 0, bytes: 2), // 47
            InstructionData(instruction: pha, mode: .implied,          cycles: 3, pageCycles: 0, bytes: 1), // 48
            InstructionData(instruction: eor, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2), // 49
            InstructionData(instruction: lsr, mode: .accumulator,      cycles: 2, pageCycles: 0, bytes: 1), // 4A
            InstructionData(instruction: alr, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2), // 4B
            InstructionData(instruction: jmp, mode: .absolute,         cycles: 3, pageCycles: 0, bytes: 3), // 4C
            InstructionData(instruction: eor, mode: .absolute,         cycles: 4, pageCycles: 0, bytes: 3), // 4D
            InstructionData(instruction: lsr, mode: .absolute,         cycles: 6, pageCycles: 0, bytes: 3), // 4E
            InstructionData(instruction: sre, mode: .absolute,         cycles: 6, pageCycles: 0, bytes: 3), // 4F
            InstructionData(instruction: bvc, mode: .relative,         cycles: 2, pageCycles: 1, bytes: 2), // 50
            InstructionData(instruction: eor, mode: .indirectYIndexed, cycles: 5, pageCycles: 1, bytes: 2), // 51
            InstructionData(instruction: kil, mode: .implied,          cycles: 1, pageCycles: 0, bytes: 1), // 52
            InstructionData(instruction: sre, mode: .indirectYIndexed, cycles: 8, pageCycles: 0, bytes: 2), // 53
            InstructionData(instruction: nop, mode: .zeroPageXIndexed, cycles: 4, pageCycles: 0, bytes: 2), // 54
            InstructionData(instruction: eor, mode: .zeroPageXIndexed, cycles: 4, pageCycles: 0, bytes: 2), // 55
            InstructionData(instruction: lsr, mode: .zeroPageXIndexed, cycles: 6, pageCycles: 0, bytes: 2), // 56
            InstructionData(instruction: sre, mode: .zeroPageXIndexed, cycles: 6, pageCycles: 0, bytes: 2), // 57
            InstructionData(instruction: cli, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1), // 58
            InstructionData(instruction: eor, mode: .absoluteYIndexed, cycles: 4, pageCycles: 1, bytes: 3), // 59
            InstructionData(instruction: nop, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1), // 5A
            InstructionData(instruction: sre, mode: .absoluteYIndexed, cycles: 7, pageCycles: 0, bytes: 3), // 5B
            InstructionData(instruction: nop, mode: .absoluteXIndexed, cycles: 4, pageCycles: 1, bytes: 3), // 5C
            InstructionData(instruction: eor, mode: .absoluteXIndexed, cycles: 4, pageCycles: 1, bytes: 3), // 5D
            InstructionData(instruction: lsr, mode: .absoluteXIndexed, cycles: 7, pageCycles: 0, bytes: 3), // 5E
            InstructionData(instruction: sre, mode: .absoluteXIndexed, cycles: 7, pageCycles: 0, bytes: 3), // 5F
            InstructionData(instruction: rts, mode: .implied,          cycles: 6, pageCycles: 0, bytes: 1), // 60
            InstructionData(instruction: adc, mode: .xIndexedIndirect, cycles: 6, pageCycles: 0, bytes: 2), // 61
            InstructionData(instruction: kil, mode: .implied,          cycles: 1, pageCycles: 0, bytes: 1), // 62
            InstructionData(instruction: rra, mode: .xIndexedIndirect, cycles: 8, pageCycles: 0, bytes: 2), // 63
            InstructionData(instruction: nop, mode: .zeropage,         cycles: 3, pageCycles: 0, bytes: 2), // 64
            InstructionData(instruction: adc, mode: .zeropage,         cycles: 3, pageCycles: 0, bytes: 2), // 65
            InstructionData(instruction: ror, mode: .zeropage,         cycles: 5, pageCycles: 0, bytes: 2), // 66
            InstructionData(instruction: rra, mode: .zeropage,         cycles: 5, pageCycles: 0, bytes: 2), // 67
            InstructionData(instruction: pla, mode: .implied,          cycles: 4, pageCycles: 0, bytes: 1), // 68
            InstructionData(instruction: adc, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2), // 69
            InstructionData(instruction: ror, mode: .accumulator,      cycles: 2, pageCycles: 0, bytes: 1), // 6A
            InstructionData(instruction: arr, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2), // 6B
            InstructionData(instruction: jmp, mode: .indirect,         cycles: 5, pageCycles: 0, bytes: 3), // 6C
            InstructionData(instruction: adc, mode: .absolute,         cycles: 4, pageCycles: 0, bytes: 3), // 6D
            InstructionData(instruction: ror, mode: .absolute,         cycles: 6, pageCycles: 0, bytes: 3), // 6E
            InstructionData(instruction: rra, mode: .absolute,         cycles: 6, pageCycles: 0, bytes: 3), // 6F
            InstructionData(instruction: bvs, mode: .relative,         cycles: 2, pageCycles: 1, bytes: 2), // 70
            InstructionData(instruction: adc, mode: .indirectYIndexed, cycles: 5, pageCycles: 1, bytes: 2), // 71
            InstructionData(instruction: kil, mode: .implied,          cycles: 1, pageCycles: 0, bytes: 1), // 72
            InstructionData(instruction: rra, mode: .indirectYIndexed, cycles: 8, pageCycles: 0, bytes: 2), // 73
            InstructionData(instruction: nop, mode: .zeroPageXIndexed, cycles: 4, pageCycles: 0, bytes: 2), // 74
            InstructionData(instruction: adc, mode: .zeroPageXIndexed, cycles: 4, pageCycles: 0, bytes: 2), // 75
            InstructionData(instruction: ror, mode: .zeroPageXIndexed, cycles: 6, pageCycles: 0, bytes: 2), // 76
            InstructionData(instruction: rra, mode: .zeroPageXIndexed, cycles: 6, pageCycles: 0, bytes: 2), // 77
            InstructionData(instruction: sei, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1), // 78
            InstructionData(instruction: adc, mode: .absoluteYIndexed, cycles: 4, pageCycles: 1, bytes: 3), // 79
            InstructionData(instruction: nop, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1), // 7A
            InstructionData(instruction: rra, mode: .absoluteYIndexed, cycles: 7, pageCycles: 0, bytes: 3), // 7B
            InstructionData(instruction: nop, mode: .absoluteXIndexed, cycles: 4, pageCycles: 1, bytes: 3), // 7C
            InstructionData(instruction: adc, mode: .absoluteXIndexed, cycles: 4, pageCycles: 1, bytes: 3), // 7D
            InstructionData(instruction: ror, mode: .absoluteXIndexed, cycles: 7, pageCycles: 0, bytes: 3), // 7E
            InstructionData(instruction: rra, mode: .absoluteXIndexed, cycles: 7, pageCycles: 0, bytes: 3), // 7F
            InstructionData(instruction: nop, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2), // 80
            InstructionData(instruction: sta, mode: .xIndexedIndirect, cycles: 6, pageCycles: 0, bytes: 2), // 81
            InstructionData(instruction: nop, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2), // 82
            InstructionData(instruction: sax, mode: .xIndexedIndirect, cycles: 6, pageCycles: 0, bytes: 2), // 83
            InstructionData(instruction: sty, mode: .zeropage,         cycles: 3, pageCycles: 0, bytes: 2), // 84
            InstructionData(instruction: sta, mode: .zeropage,         cycles: 3, pageCycles: 0, bytes: 2), // 85
            InstructionData(instruction: stx, mode: .zeropage,         cycles: 3, pageCycles: 0, bytes: 2), // 86
            InstructionData(instruction: sax, mode: .zeropage,         cycles: 3, pageCycles: 0, bytes: 2), // 87
            InstructionData(instruction: dey, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1), // 88
            InstructionData(instruction: nop, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2), // 89
            InstructionData(instruction: txa, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1), // 8A
            InstructionData(instruction: xaa, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2), // 8B
            InstructionData(instruction: sty, mode: .absolute,         cycles: 4, pageCycles: 0, bytes: 3), // 8C
            InstructionData(instruction: sta, mode: .absolute,         cycles: 4, pageCycles: 0, bytes: 3), // 8D
            InstructionData(instruction: stx, mode: .absolute,         cycles: 4, pageCycles: 0, bytes: 3), // 8E
            InstructionData(instruction: sax, mode: .absolute,         cycles: 4, pageCycles: 0, bytes: 3), // 8F
            InstructionData(instruction: bcc, mode: .relative,         cycles: 2, pageCycles: 1, bytes: 2), // 90
            InstructionData(instruction: sta, mode: .indirectYIndexed, cycles: 6, pageCycles: 0, bytes: 2), // 91
            InstructionData(instruction: kil, mode: .implied,          cycles: 1, pageCycles: 0, bytes: 1), // 92
            InstructionData(instruction: ahx, mode: .indirectYIndexed, cycles: 6, pageCycles: 0, bytes: 2), // 93
            InstructionData(instruction: sty, mode: .zeroPageXIndexed, cycles: 4, pageCycles: 0, bytes: 2), // 94
            InstructionData(instruction: sta, mode: .zeroPageXIndexed, cycles: 4, pageCycles: 0, bytes: 2), // 95
            InstructionData(instruction: stx, mode: .zeroPageYIndexed, cycles: 4, pageCycles: 0, bytes: 2), // 96
            InstructionData(instruction: sax, mode: .zeroPageYIndexed, cycles: 4, pageCycles: 0, bytes: 2), // 97
            InstructionData(instruction: tya, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1), // 98
            InstructionData(instruction: sta, mode: .absoluteYIndexed, cycles: 5, pageCycles: 0, bytes: 3), // 99
            InstructionData(instruction: txs, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1), // 9A
            InstructionData(instruction: tas, mode: .absoluteYIndexed, cycles: 5, pageCycles: 0, bytes: 3), // 9B
            InstructionData(instruction: shy, mode: .absoluteXIndexed, cycles: 5, pageCycles: 0, bytes: 3), // 9C
            InstructionData(instruction: sta, mode: .absoluteXIndexed, cycles: 5, pageCycles: 0, bytes: 3), // 9D
            InstructionData(instruction: shx, mode: .absoluteYIndexed, cycles: 5, pageCycles: 0, bytes: 3), // 9E
            InstructionData(instruction: ahx, mode: .absoluteYIndexed, cycles: 5, pageCycles: 0, bytes: 3), // 9F
            InstructionData(instruction: ldy, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2), // A0
            InstructionData(instruction: lda, mode: .xIndexedIndirect, cycles: 6, pageCycles: 0, bytes: 2), // A1
            InstructionData(instruction: ldx, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2), // A2
            InstructionData(instruction: lax, mode: .xIndexedIndirect, cycles: 6, pageCycles: 0, bytes: 2), // A3
            InstructionData(instruction: ldy, mode: .zeropage,         cycles: 3, pageCycles: 0, bytes: 2), // A4
            InstructionData(instruction: lda, mode: .zeropage,         cycles: 3, pageCycles: 0, bytes: 2), // A5
            InstructionData(instruction: ldx, mode: .zeropage,         cycles: 3, pageCycles: 0, bytes: 2), // A6
            InstructionData(instruction: lax, mode: .zeropage,         cycles: 3, pageCycles: 0, bytes: 2), // A7
            InstructionData(instruction: tay, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1), // A8
            InstructionData(instruction: lda, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2), // A9
            InstructionData(instruction: tax, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1), // AA
            InstructionData(instruction: lax, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2), // AB
            InstructionData(instruction: ldy, mode: .absolute,         cycles: 4, pageCycles: 0, bytes: 3), // AC
            InstructionData(instruction: lda, mode: .absolute,         cycles: 4, pageCycles: 0, bytes: 3), // AD
            InstructionData(instruction: ldx, mode: .absolute,         cycles: 4, pageCycles: 0, bytes: 3), // AE
            InstructionData(instruction: lax, mode: .absolute,         cycles: 4, pageCycles: 0, bytes: 3), // AF
            InstructionData(instruction: bcs, mode: .relative,         cycles: 2, pageCycles: 1, bytes: 2), // B0
            InstructionData(instruction: lda, mode: .indirectYIndexed, cycles: 5, pageCycles: 1, bytes: 2), // B1
            InstructionData(instruction: kil, mode: .implied,          cycles: 1, pageCycles: 0, bytes: 1), // B2
            InstructionData(instruction: lax, mode: .indirectYIndexed, cycles: 5, pageCycles: 1, bytes: 2), // B3
            InstructionData(instruction: ldy, mode: .zeroPageXIndexed, cycles: 4, pageCycles: 0, bytes: 2), // B4
            InstructionData(instruction: lda, mode: .zeroPageXIndexed, cycles: 4, pageCycles: 0, bytes: 2), // B5
            InstructionData(instruction: ldx, mode: .zeroPageYIndexed, cycles: 4, pageCycles: 0, bytes: 2), // B6
            InstructionData(instruction: lax, mode: .zeroPageYIndexed, cycles: 4, pageCycles: 0, bytes: 2), // B7
            InstructionData(instruction: clv, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1), // B8
            InstructionData(instruction: lda, mode: .absoluteYIndexed, cycles: 4, pageCycles: 1, bytes: 3), // B9
            InstructionData(instruction: tsx, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1), // BA
            InstructionData(instruction: las, mode: .absoluteYIndexed, cycles: 4, pageCycles: 1, bytes: 3), // BB
            InstructionData(instruction: ldy, mode: .absoluteXIndexed, cycles: 4, pageCycles: 1, bytes: 3), // BC
            InstructionData(instruction: lda, mode: .absoluteXIndexed, cycles: 4, pageCycles: 1, bytes: 3), // BD
            InstructionData(instruction: ldx, mode: .absoluteYIndexed, cycles: 4, pageCycles: 1, bytes: 3), // BE
            InstructionData(instruction: lax, mode: .absoluteYIndexed, cycles: 4, pageCycles: 1, bytes: 3), // BF
            InstructionData(instruction: cpy, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2), // C0
            InstructionData(instruction: cmp, mode: .xIndexedIndirect, cycles: 6, pageCycles: 0, bytes: 2), // C1
            InstructionData(instruction: nop, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2), // C2
            InstructionData(instruction: dcp, mode: .xIndexedIndirect, cycles: 8, pageCycles: 0, bytes: 2), // C3
            InstructionData(instruction: cpy, mode: .zeropage,         cycles: 3, pageCycles: 0, bytes: 2), // C4
            InstructionData(instruction: cmp, mode: .zeropage,         cycles: 3, pageCycles: 0, bytes: 2), // C5
            InstructionData(instruction: dec, mode: .zeropage,         cycles: 5, pageCycles: 0, bytes: 2), // C6
            InstructionData(instruction: dcp, mode: .zeropage,         cycles: 5, pageCycles: 0, bytes: 2), // C7
            InstructionData(instruction: iny, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1), // C8
            InstructionData(instruction: cmp, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2), // C9
            InstructionData(instruction: dex, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1), // CA
            InstructionData(instruction: sbx, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2), // CB
            InstructionData(instruction: cpy, mode: .absolute,         cycles: 4, pageCycles: 0, bytes: 3), // CC
            InstructionData(instruction: cmp, mode: .absolute,         cycles: 4, pageCycles: 0, bytes: 3), // CD
            InstructionData(instruction: dec, mode: .absolute,         cycles: 6, pageCycles: 0, bytes: 3), // CE
            InstructionData(instruction: dcp, mode: .absolute,         cycles: 6, pageCycles: 0, bytes: 3), // CF
            InstructionData(instruction: bne, mode: .relative,         cycles: 2, pageCycles: 1, bytes: 2), // D0
            InstructionData(instruction: cmp, mode: .indirectYIndexed, cycles: 5, pageCycles: 1, bytes: 2), // D1
            InstructionData(instruction: kil, mode: .implied,          cycles: 1, pageCycles: 0, bytes: 1), // D2
            InstructionData(instruction: dcp, mode: .indirectYIndexed, cycles: 8, pageCycles: 0, bytes: 2), // D3
            InstructionData(instruction: nop, mode: .zeroPageXIndexed, cycles: 4, pageCycles: 0, bytes: 2), // D4
            InstructionData(instruction: cmp, mode: .zeroPageXIndexed, cycles: 4, pageCycles: 0, bytes: 2), // D5
            InstructionData(instruction: dec, mode: .zeroPageXIndexed, cycles: 6, pageCycles: 0, bytes: 2), // D6
            InstructionData(instruction: dcp, mode: .zeroPageXIndexed, cycles: 6, pageCycles: 0, bytes: 2), // D7
            InstructionData(instruction: cld, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1), // D8
            InstructionData(instruction: cmp, mode: .absoluteYIndexed, cycles: 4, pageCycles: 1, bytes: 3), // D9
            InstructionData(instruction: nop, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1), // DA
            InstructionData(instruction: dcp, mode: .absoluteYIndexed, cycles: 7, pageCycles: 0, bytes: 3), // DB
            InstructionData(instruction: nop, mode: .absoluteXIndexed, cycles: 4, pageCycles: 1, bytes: 3), // DC
            InstructionData(instruction: cmp, mode: .absoluteXIndexed, cycles: 4, pageCycles: 1, bytes: 3), // DD
            InstructionData(instruction: dec, mode: .absoluteXIndexed, cycles: 7, pageCycles: 0, bytes: 3), // DE
            InstructionData(instruction: dcp, mode: .absoluteXIndexed, cycles: 7, pageCycles: 0, bytes: 3), // DF
            InstructionData(instruction: cpx, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2), // E0
            InstructionData(instruction: sbc, mode: .xIndexedIndirect, cycles: 6, pageCycles: 0, bytes: 2), // E1
            InstructionData(instruction: nop, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2), // E2
            InstructionData(instruction: isc, mode: .xIndexedIndirect, cycles: 8, pageCycles: 0, bytes: 2), // E3
            InstructionData(instruction: cpx, mode: .zeropage,         cycles: 3, pageCycles: 0, bytes: 2), // E4
            InstructionData(instruction: sbc, mode: .zeropage,         cycles: 3, pageCycles: 0, bytes: 2), // E5
            InstructionData(instruction: inc, mode: .zeropage,         cycles: 5, pageCycles: 0, bytes: 2), // E6
            InstructionData(instruction: isc, mode: .zeropage,         cycles: 5, pageCycles: 0, bytes: 2), // E7
            InstructionData(instruction: inx, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1), // E8
            InstructionData(instruction: sbc, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2), // E9
            InstructionData(instruction: nop, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1), // EA
            InstructionData(instruction: sbc, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2), // EB
            InstructionData(instruction: cpx, mode: .absolute,         cycles: 4, pageCycles: 0, bytes: 3), // EC
            InstructionData(instruction: sbc, mode: .absolute,         cycles: 4, pageCycles: 0, bytes: 3), // ED
            InstructionData(instruction: inc, mode: .absolute,         cycles: 6, pageCycles: 0, bytes: 3), // EE
            InstructionData(instruction: isc, mode: .absolute,         cycles: 6, pageCycles: 0, bytes: 3), // EF
            InstructionData(instruction: beq, mode: .relative,         cycles: 2, pageCycles: 1, bytes: 2), // F0
            InstructionData(instruction: sbc, mode: .indirectYIndexed, cycles: 5, pageCycles: 1, bytes: 2), // F1
            InstructionData(instruction: kil, mode: .implied,          cycles: 1, pageCycles: 0, bytes: 1), // F2
            InstructionData(instruction: isc, mode: .indirectYIndexed, cycles: 8, pageCycles: 0, bytes: 2), // F3
            InstructionData(instruction: nop, mode: .zeroPageXIndexed, cycles: 4, pageCycles: 0, bytes: 2), // F4
            InstructionData(instruction: sbc, mode: .zeroPageXIndexed, cycles: 4, pageCycles: 0, bytes: 2), // F5
            InstructionData(instruction: inc, mode: .zeroPageXIndexed, cycles: 6, pageCycles: 0, bytes: 2), // F6
            InstructionData(instruction: isc, mode: .zeroPageXIndexed, cycles: 6, pageCycles: 0, bytes: 2), // F7
            InstructionData(instruction: sed, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1), // F8
            InstructionData(instruction: sbc, mode: .absoluteYIndexed, cycles: 4, pageCycles: 1, bytes: 3), // F9
            InstructionData(instruction: nop, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1), // FA
            InstructionData(instruction: isc, mode: .absoluteYIndexed, cycles: 7, pageCycles: 0, bytes: 3), // FB
            InstructionData(instruction: nop, mode: .absoluteXIndexed, cycles: 4, pageCycles: 1, bytes: 3), // FC
            InstructionData(instruction: sbc, mode: .absoluteXIndexed, cycles: 4, pageCycles: 1, bytes: 3), // FD
            InstructionData(instruction: inc, mode: .absoluteXIndexed, cycles: 7, pageCycles: 0, bytes: 3), // FE
            InstructionData(instruction: isc, mode: .absoluteXIndexed, cycles: 7, pageCycles: 0, bytes: 3), // FF
        ]
    }
}
