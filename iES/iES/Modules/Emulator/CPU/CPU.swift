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
    var isStopped: Bool = false
    
    init(ppu: PPU) {
        self.ppu = ppu
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
        case 0x4014:
            let startIndex: Int = Int(UInt16(value) << 8)
            self.ppu.writeOAMDMA(oamDMA: [UInt8](self.ram[startIndex ..< startIndex + 256]))
            self.stall += (self.cycles % 2 == 0) ? 513 : 514
        case 0x5000 ... 0xFFFF:
            self.ppu.mapper.cpuWrite(address: address, value: value)
            // TODO: other cases
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

extension CPU {
    
    /// execute instruction and returns number of steps
    func step() -> Int {
        
        // TODO: Don't foreget to finish this thing
        let numCPUCyclesThisStep: Int
        
        guard self.stall == 0
        else
        {
            numCPUCyclesThisStep = 1
            stall -= 1
            stepOthers(for: numCPUCyclesThisStep)
            return numCPUCyclesThisStep
        }
        
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
        
        let oldCycles = cycles
        
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
            
            if zero == 0xFF
            {
                address = UInt16(read(address: 0x00FF)) | (UInt16(read(address: 0x0000)) << 8)
            }
            else
            {
                address = read16bug(address: UInt16(zero))
            }
            
            pageCrossed = false
        case .indirect:
            let vector = read16(address: pc &+ 1)
            if vector & 0x00FF == 0x00FF
            {
                let lo = read(address: vector)
                let hi = read(address: vector &- 0x00FF)
                address = UInt16(lo) | (UInt16(hi) << 8)
            }
            else
            {
                address = read16bug(address: vector)
            }
            pageCrossed = false
        case .indirectYIndexed:
            let zero: UInt8 = read(address: pc &+ 1)
            
            if zero == 0xFF
            {
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
        if pageCrossed
        {
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
        for _ in 0 ..< numCPUCycles * 3
        {
            let ppuStepResults: PPUStepResults = self.ppu.step()
            if let safeRequestedInterrupt: Interrupt = ppuStepResults.requestedCPUInterrupt
            {
                switch safeRequestedInterrupt
                {
                case .irq: self.triggerIRQ()
                case .nmi: self.triggerNMI()
                case .none: self.interrupt = .none
                }
            }
        }
        // APU step
    }
}

extension CPU {
    
    /// reuturns all combinations of instructions
    private func getInstrutcionTable() -> [InstructionData] {
        // TODO: add illegal instructions
        return [
            .init(instruction: brk, mode: .implied,          cycles: 7, pageCycles: 0, bytes: 2),
            .init(instruction: ora, mode: .xIndexedIndirect, cycles: 6, pageCycles: 0, bytes: 2),
            .init(instruction: nop, mode: .zeropage,         cycles: 3, pageCycles: 0, bytes: 2),
            .init(instruction: ora, mode: .zeropage,         cycles: 3, pageCycles: 0, bytes: 2),
            .init(instruction: asl, mode: .zeropage,         cycles: 5, pageCycles: 0, bytes: 2),
            .init(instruction: php, mode: .implied,          cycles: 3, pageCycles: 0, bytes: 1),
            .init(instruction: ora, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2),
            .init(instruction: asl, mode: .accumulator,      cycles: 2, pageCycles: 0, bytes: 1),
            .init(instruction: nop, mode: .absolute,         cycles: 4, pageCycles: 0, bytes: 3),
            .init(instruction: ora, mode: .absolute,         cycles: 4, pageCycles: 0, bytes: 3),
            .init(instruction: asl, mode: .absolute,         cycles: 6, pageCycles: 0, bytes: 3),
            .init(instruction: bpl, mode: .relative,         cycles: 2, pageCycles: 1, bytes: 2),
            .init(instruction: ora, mode: .indirectYIndexed, cycles: 5, pageCycles: 1, bytes: 2),
            .init(instruction: nop, mode: .zeroPageXIndexed, cycles: 4, pageCycles: 0, bytes: 2),
            .init(instruction: ora, mode: .zeroPageXIndexed, cycles: 4, pageCycles: 0, bytes: 2),
            .init(instruction: asl, mode: .zeroPageXIndexed, cycles: 6, pageCycles: 0, bytes: 2),
            .init(instruction: clc, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1),
            .init(instruction: ora, mode: .absoluteYIndexed, cycles: 4, pageCycles: 1, bytes: 3),
            .init(instruction: nop, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1),
            .init(instruction: nop, mode: .absoluteXIndexed, cycles: 4, pageCycles: 1, bytes: 3),
            .init(instruction: ora, mode: .absoluteXIndexed, cycles: 4, pageCycles: 1, bytes: 3),
            .init(instruction: asl, mode: .absoluteXIndexed, cycles: 7, pageCycles: 0, bytes: 3),
            .init(instruction: jsr, mode: .absolute,         cycles: 6, pageCycles: 0, bytes: 3),
            .init(instruction: and, mode: .xIndexedIndirect, cycles: 6, pageCycles: 0, bytes: 2),
            .init(instruction: bit, mode: .zeropage,         cycles: 3, pageCycles: 0, bytes: 2),
            .init(instruction: and, mode: .zeropage,         cycles: 3, pageCycles: 0, bytes: 2),
            .init(instruction: rol, mode: .zeropage,         cycles: 5, pageCycles: 0, bytes: 2),
            .init(instruction: plp, mode: .implied,          cycles: 4, pageCycles: 0, bytes: 1),
            .init(instruction: and, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2),
            .init(instruction: rol, mode: .accumulator,      cycles: 2, pageCycles: 0, bytes: 1),
            .init(instruction: bit, mode: .absolute,         cycles: 4, pageCycles: 0, bytes: 3),
            .init(instruction: and, mode: .absolute,         cycles: 4, pageCycles: 0, bytes: 3),
            .init(instruction: rol, mode: .absolute,         cycles: 6, pageCycles: 0, bytes: 3),
            .init(instruction: bmi, mode: .relative,         cycles: 2, pageCycles: 1, bytes: 2),
            .init(instruction: and, mode: .indirectYIndexed, cycles: 5, pageCycles: 1, bytes: 2),
            .init(instruction: nop, mode: .zeroPageXIndexed, cycles: 4, pageCycles: 0, bytes: 2),
            .init(instruction: and, mode: .zeroPageXIndexed, cycles: 4, pageCycles: 0, bytes: 2),
            .init(instruction: rol, mode: .zeroPageXIndexed, cycles: 6, pageCycles: 0, bytes: 2),
            .init(instruction: sec, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1),
            .init(instruction: and, mode: .absoluteYIndexed, cycles: 4, pageCycles: 1, bytes: 3),
            .init(instruction: nop, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1),
            .init(instruction: nop, mode: .absoluteXIndexed, cycles: 4, pageCycles: 1, bytes: 3),
            .init(instruction: and, mode: .absoluteXIndexed, cycles: 4, pageCycles: 1, bytes: 3),
            .init(instruction: rol, mode: .absoluteXIndexed, cycles: 7, pageCycles: 0, bytes: 3),
            .init(instruction: rti, mode: .implied,          cycles: 6, pageCycles: 0, bytes: 1),
            .init(instruction: eor, mode: .xIndexedIndirect, cycles: 6, pageCycles: 0, bytes: 2),
            .init(instruction: nop, mode: .zeropage,         cycles: 3, pageCycles: 0, bytes: 2),
            .init(instruction: eor, mode: .zeropage,         cycles: 3, pageCycles: 0, bytes: 2),
            .init(instruction: lsr, mode: .zeropage,         cycles: 5, pageCycles: 0, bytes: 2),
            .init(instruction: pha, mode: .implied,          cycles: 3, pageCycles: 0, bytes: 1),
            .init(instruction: eor, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2),
            .init(instruction: lsr, mode: .accumulator,      cycles: 2, pageCycles: 0, bytes: 1),
            .init(instruction: jmp, mode: .absolute,         cycles: 3, pageCycles: 0, bytes: 3),
            .init(instruction: eor, mode: .absolute,         cycles: 4, pageCycles: 0, bytes: 3),
            .init(instruction: lsr, mode: .absolute,         cycles: 6, pageCycles: 0, bytes: 3),
            .init(instruction: bvc, mode: .relative,         cycles: 2, pageCycles: 1, bytes: 2),
            .init(instruction: eor, mode: .indirectYIndexed, cycles: 5, pageCycles: 1, bytes: 2),
            .init(instruction: nop, mode: .zeroPageXIndexed, cycles: 4, pageCycles: 0, bytes: 2),
            .init(instruction: eor, mode: .zeroPageXIndexed, cycles: 4, pageCycles: 0, bytes: 2),
            .init(instruction: lsr, mode: .zeroPageXIndexed, cycles: 6, pageCycles: 0, bytes: 2),
            .init(instruction: cli, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1),
            .init(instruction: eor, mode: .absoluteYIndexed, cycles: 4, pageCycles: 1, bytes: 3),
            .init(instruction: nop, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1),
            .init(instruction: nop, mode: .absoluteXIndexed, cycles: 4, pageCycles: 1, bytes: 3),
            .init(instruction: eor, mode: .absoluteXIndexed, cycles: 4, pageCycles: 1, bytes: 3),
            .init(instruction: lsr, mode: .absoluteXIndexed, cycles: 7, pageCycles: 0, bytes: 3),
            .init(instruction: rts, mode: .implied,          cycles: 6, pageCycles: 0, bytes: 1),
            .init(instruction: adc, mode: .xIndexedIndirect, cycles: 6, pageCycles: 0, bytes: 2),
            .init(instruction: nop, mode: .zeropage,         cycles: 3, pageCycles: 0, bytes: 2),
            .init(instruction: adc, mode: .zeropage,         cycles: 3, pageCycles: 0, bytes: 2),
            .init(instruction: ror, mode: .zeropage,         cycles: 5, pageCycles: 0, bytes: 2),
            .init(instruction: pla, mode: .implied,          cycles: 4, pageCycles: 0, bytes: 1),
            .init(instruction: adc, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2),
            .init(instruction: ror, mode: .accumulator,      cycles: 2, pageCycles: 0, bytes: 1),
            .init(instruction: jmp, mode: .indirect,         cycles: 5, pageCycles: 0, bytes: 3),
            .init(instruction: adc, mode: .absolute,         cycles: 4, pageCycles: 0, bytes: 3),
            .init(instruction: ror, mode: .absolute,         cycles: 6, pageCycles: 0, bytes: 3),
            .init(instruction: bvs, mode: .relative,         cycles: 2, pageCycles: 1, bytes: 2),
            .init(instruction: adc, mode: .indirectYIndexed, cycles: 5, pageCycles: 1, bytes: 2),
            .init(instruction: nop, mode: .zeroPageXIndexed, cycles: 4, pageCycles: 0, bytes: 2),
            .init(instruction: adc, mode: .zeroPageXIndexed, cycles: 4, pageCycles: 0, bytes: 2),
            .init(instruction: ror, mode: .zeroPageXIndexed, cycles: 6, pageCycles: 0, bytes: 2),
            .init(instruction: sei, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1),
            .init(instruction: adc, mode: .absoluteYIndexed, cycles: 4, pageCycles: 1, bytes: 3),
            .init(instruction: nop, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1),
            .init(instruction: nop, mode: .absoluteXIndexed, cycles: 4, pageCycles: 1, bytes: 3),
            .init(instruction: adc, mode: .absoluteXIndexed, cycles: 4, pageCycles: 1, bytes: 3),
            .init(instruction: ror, mode: .absoluteXIndexed, cycles: 7, pageCycles: 0, bytes: 3),
            .init(instruction: nop, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2),
            .init(instruction: sta, mode: .xIndexedIndirect, cycles: 6, pageCycles: 0, bytes: 2),
            .init(instruction: nop, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2),
            .init(instruction: sty, mode: .zeropage,         cycles: 3, pageCycles: 0, bytes: 2),
            .init(instruction: sta, mode: .zeropage,         cycles: 3, pageCycles: 0, bytes: 2),
            .init(instruction: stx, mode: .zeropage,         cycles: 3, pageCycles: 0, bytes: 2),
            .init(instruction: dey, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1),
            .init(instruction: nop, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2),
            .init(instruction: txa, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1),
            .init(instruction: sty, mode: .absolute,         cycles: 4, pageCycles: 0, bytes: 3),
            .init(instruction: sta, mode: .absolute,         cycles: 4, pageCycles: 0, bytes: 3),
            .init(instruction: stx, mode: .absolute,         cycles: 4, pageCycles: 0, bytes: 3),
            .init(instruction: bcc, mode: .relative,         cycles: 2, pageCycles: 1, bytes: 2),
            .init(instruction: sta, mode: .indirectYIndexed, cycles: 6, pageCycles: 0, bytes: 2),
            .init(instruction: sty, mode: .zeroPageXIndexed, cycles: 4, pageCycles: 0, bytes: 2),
            .init(instruction: sta, mode: .zeroPageXIndexed, cycles: 4, pageCycles: 0, bytes: 2),
            .init(instruction: stx, mode: .zeroPageYIndexed, cycles: 4, pageCycles: 0, bytes: 2),
            .init(instruction: tya, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1),
            .init(instruction: sta, mode: .absoluteYIndexed, cycles: 5, pageCycles: 0, bytes: 3),
            .init(instruction: txs, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1),
            .init(instruction: sta, mode: .absoluteXIndexed, cycles: 5, pageCycles: 0, bytes: 3),
            .init(instruction: ldy, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2),
            .init(instruction: lda, mode: .xIndexedIndirect, cycles: 6, pageCycles: 0, bytes: 2),
            .init(instruction: ldx, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2),
            .init(instruction: ldy, mode: .zeropage,         cycles: 3, pageCycles: 0, bytes: 2),
            .init(instruction: lda, mode: .zeropage,         cycles: 3, pageCycles: 0, bytes: 2),
            .init(instruction: ldx, mode: .zeropage,         cycles: 3, pageCycles: 0, bytes: 2),
            .init(instruction: tay, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1),
            .init(instruction: lda, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2),
            .init(instruction: tax, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1),
            .init(instruction: ldy, mode: .absolute,         cycles: 4, pageCycles: 0, bytes: 3),
            .init(instruction: lda, mode: .absolute,         cycles: 4, pageCycles: 0, bytes: 3),
            .init(instruction: ldx, mode: .absolute,         cycles: 4, pageCycles: 0, bytes: 3),
            .init(instruction: bcs, mode: .relative,         cycles: 2, pageCycles: 1, bytes: 2),
            .init(instruction: lda, mode: .indirectYIndexed, cycles: 5, pageCycles: 1, bytes: 2),
            .init(instruction: ldy, mode: .zeroPageXIndexed, cycles: 4, pageCycles: 0, bytes: 2),
            .init(instruction: lda, mode: .zeroPageXIndexed, cycles: 4, pageCycles: 0, bytes: 2),
            .init(instruction: ldx, mode: .zeroPageYIndexed, cycles: 4, pageCycles: 0, bytes: 2),
            .init(instruction: clv, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1),
            .init(instruction: lda, mode: .absoluteYIndexed, cycles: 4, pageCycles: 1, bytes: 3),
            .init(instruction: tsx, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1),
            .init(instruction: ldy, mode: .absoluteXIndexed, cycles: 4, pageCycles: 1, bytes: 3),
            .init(instruction: lda, mode: .absoluteXIndexed, cycles: 4, pageCycles: 1, bytes: 3),
            .init(instruction: ldx, mode: .absoluteYIndexed, cycles: 4, pageCycles: 1, bytes: 3),
            .init(instruction: cpy, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2),
            .init(instruction: cmp, mode: .xIndexedIndirect, cycles: 6, pageCycles: 0, bytes: 2),
            .init(instruction: nop, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2),
            .init(instruction: cpy, mode: .zeropage,         cycles: 3, pageCycles: 0, bytes: 2),
            .init(instruction: cmp, mode: .zeropage,         cycles: 3, pageCycles: 0, bytes: 2),
            .init(instruction: dec, mode: .zeropage,         cycles: 5, pageCycles: 0, bytes: 2),
            .init(instruction: iny, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1),
            .init(instruction: cmp, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2),
            .init(instruction: dex, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1),
            .init(instruction: cpy, mode: .absolute,         cycles: 4, pageCycles: 0, bytes: 3),
            .init(instruction: cmp, mode: .absolute,         cycles: 4, pageCycles: 0, bytes: 3),
            .init(instruction: dec, mode: .absolute,         cycles: 6, pageCycles: 0, bytes: 3),
            .init(instruction: bne, mode: .relative,         cycles: 2, pageCycles: 1, bytes: 2),
            .init(instruction: cmp, mode: .indirectYIndexed, cycles: 5, pageCycles: 1, bytes: 2),
            .init(instruction: nop, mode: .zeroPageXIndexed, cycles: 4, pageCycles: 0, bytes: 2),
            .init(instruction: cmp, mode: .zeroPageXIndexed, cycles: 4, pageCycles: 0, bytes: 2),
            .init(instruction: dec, mode: .zeroPageXIndexed, cycles: 6, pageCycles: 0, bytes: 2),
            .init(instruction: cld, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1),
            .init(instruction: cmp, mode: .absoluteYIndexed, cycles: 4, pageCycles: 1, bytes: 3),
            .init(instruction: nop, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1),
            .init(instruction: nop, mode: .absoluteXIndexed, cycles: 4, pageCycles: 1, bytes: 3),
            .init(instruction: cmp, mode: .absoluteXIndexed, cycles: 4, pageCycles: 1, bytes: 3),
            .init(instruction: dec, mode: .absoluteXIndexed, cycles: 7, pageCycles: 0, bytes: 3),
            .init(instruction: cpx, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2),
            .init(instruction: sbc, mode: .xIndexedIndirect, cycles: 6, pageCycles: 0, bytes: 2),
            .init(instruction: nop, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2),
            .init(instruction: cpx, mode: .zeropage,         cycles: 3, pageCycles: 0, bytes: 2),
            .init(instruction: sbc, mode: .zeropage,         cycles: 3, pageCycles: 0, bytes: 2),
            .init(instruction: inx, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1),
            .init(instruction: sbc, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2),
            .init(instruction: nop, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1),
            .init(instruction: sbc, mode: .immediate,        cycles: 2, pageCycles: 0, bytes: 2),
            .init(instruction: cpx, mode: .absolute,         cycles: 4, pageCycles: 0, bytes: 3),
            .init(instruction: sbc, mode: .absolute,         cycles: 4, pageCycles: 0, bytes: 3),
            .init(instruction: beq, mode: .relative,         cycles: 2, pageCycles: 1, bytes: 2),
            .init(instruction: sbc, mode: .indirectYIndexed, cycles: 5, pageCycles: 1, bytes: 2),
            .init(instruction: nop, mode: .zeroPageXIndexed, cycles: 4, pageCycles: 0, bytes: 2),
            .init(instruction: sbc, mode: .zeroPageXIndexed, cycles: 4, pageCycles: 0, bytes: 2),
            .init(instruction: sed, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1),
            .init(instruction: sbc, mode: .absoluteYIndexed, cycles: 4, pageCycles: 1, bytes: 3),
            .init(instruction: nop, mode: .implied,          cycles: 2, pageCycles: 0, bytes: 1),
            .init(instruction: nop, mode: .absoluteXIndexed, cycles: 4, pageCycles: 1, bytes: 3),
            .init(instruction: sbc, mode: .absoluteXIndexed, cycles: 4, pageCycles: 1, bytes: 3),
        ]
    }
}
