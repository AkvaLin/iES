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
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        cpu = MockedCPU()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        cpu = nil
    }
    
    func testSetZ() {
        cpu.setZ(value: 0)
        
        XCTAssertTrue(cpu.z)
        
        cpu.setZ(value: 0x05)
        
        XCTAssertFalse(cpu.z)
    }
    
    func testSetN() {
        cpu.setN(value: 0xFF)
        
        XCTAssertTrue(cpu.n)
        
        cpu.setN(value: 0x00)
        
        XCTAssertFalse(cpu.n)
    }
    
    func testLDA() {
        let address: UInt16 = 0x0000
        let value: UInt8 = 0x05
        cpu.ram[Int(address % 0x0800)] = value
        cpu.lda(address: address)
        
        XCTAssertEqual(value, cpu.a)
        XCTAssertFalse(cpu.z)
        XCTAssertFalse(cpu.n)
    }
    
    func testTAX() {
        let address: UInt16 = 0x0000
        let value: UInt8 = 0x05
        cpu.ram[Int(address % 0x0800)] = value
        cpu.lda(address: address)
        
        cpu.tax()
        
        XCTAssertEqual(cpu.a, cpu.x)
        XCTAssertFalse(cpu.z)
        XCTAssertFalse(cpu.n)
    }
    
    func testTAY() {
        let address: UInt16 = 0x0000
        let value: UInt8 = 0x05
        cpu.ram[Int(address % 0x0800)] = value
        cpu.lda(address: address)
        
        cpu.tay()
        
        XCTAssertEqual(cpu.a, cpu.y)
        XCTAssertFalse(cpu.z)
        XCTAssertFalse(cpu.n)
    }
    
    func testDEX() {
        let address: UInt16 = 0x0000
        let value: UInt8 = 0x01
        cpu.ram[Int(address % 0x0800)] = value
        cpu.ldx(address: address)
        
        cpu.dex()
        
        XCTAssertEqual(cpu.x, 0x00)
        XCTAssertTrue(cpu.z)
        XCTAssertFalse(cpu.n)
    }
    
    func testDEXOverflow() {
        let address: UInt16 = 0x0000
        let value: UInt8 = 0x00
        cpu.ram[Int(address % 0x0800)] = value
        cpu.ldx(address: address)
        
        cpu.dex()
        
        XCTAssertEqual(cpu.x, UInt8.max)
        XCTAssertFalse(cpu.z)
        XCTAssertTrue(cpu.n)
    }
}
