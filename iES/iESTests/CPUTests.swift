//
//  CPUTests.swift
//  iESTests
//
//  Created by Никита Пивоваров on 08.06.2024.
//

import XCTest
@testable import iES

final class CPUTests: XCTestCase {

    var cpu: MockedCPU!
    
    func testLDA() {
        cpu = MockedCPU()
        
        let address: UInt16 = 0x0000
        let value: UInt8 = 0x05
        cpu.ram[Int(address % 0x0800)] = value
        cpu.lda(addres: address)
        
        XCTAssertEqual(value, cpu.a)
        XCTAssertFalse(cpu.z)
        XCTAssertFalse(cpu.n)
        
        let secondValue: UInt8 = 0x00
        cpu.ram[Int(address % 0x0800)] = secondValue
        cpu.lda(addres: address)
        
        XCTAssertEqual(secondValue, cpu.a)
        XCTAssertTrue(cpu.z)
        XCTAssertFalse(cpu.n)
        
        let thirdValue: UInt8 = 0xFF
        cpu.ram[Int(address % 0x0800)] = thirdValue
        cpu.lda(addres: address)
        
        XCTAssertEqual(thirdValue, cpu.a)
        XCTAssertFalse(cpu.z)
        XCTAssertTrue(cpu.n)
    }
}
