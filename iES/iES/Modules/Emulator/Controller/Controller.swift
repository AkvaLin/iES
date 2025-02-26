//
//  Controller.swift
//  iES
//
//  Created by Никита Пивоваров on 17.11.2024.
//


struct Controller {
    private var index: UInt8 = 0
    private var buttons: [Bool] = [Bool].init(repeating: false, count: 8)
    private var strobe: UInt8 = 0
    
    mutating func read() -> UInt8 {
        var value: UInt8 = 0
        
        if self.index < 8 && self.buttons[Int(self.index)] {
            value = 1
        }
        
        self.index += 1
        
        if self.strobe & 1 == 1 {
            self.index = 0
        }
        
        return value
    }
    
    mutating func write(value: UInt8) {
        self.strobe = value
        if self.strobe & 1 == 1 {
            self.index = 0
        }
    }
    
    mutating func set(buttons: [Bool]) {
        self.buttons = buttons
    }
    
    mutating func set(buttonAtIndex index: Int, enabled: Bool) {
        guard index < 8 else { return }
        self.buttons[index] = enabled
    }
}
