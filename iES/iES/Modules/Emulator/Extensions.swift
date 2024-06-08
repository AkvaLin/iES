//
//  Extensions.swift
//  iES
//
//  Created by Никита Пивоваров on 01.06.2024.
//

import Foundation

extension UInt8
{
    /// Returns an array of booleans
    var littleEndianBitArray: [Bool] {
        let lE = self.littleEndian
        var retValue: [Bool] = [Bool].init(repeating: false, count: 8)
        
        retValue[0] = lE >> 0 & 1 == 1
        retValue[1] = lE >> 1 & 1 == 1
        retValue[2] = lE >> 2 & 1 == 1
        retValue[3] = lE >> 3 & 1 == 1
        retValue[4] = lE >> 4 & 1 == 1
        retValue[5] = lE >> 5 & 1 == 1
        retValue[6] = lE >> 6 & 1 == 1
        retValue[7] = lE >> 7 & 1 == 1
        
        return retValue
    }
    
    /// Returns a UInt8 value from an array of 8 boolean values
    init(fromLittleEndianBitArray aLittleEndianBitArray: [Bool]) {
        var retValue: UInt8 = 0
        if aLittleEndianBitArray.count == 8
        {
            retValue += aLittleEndianBitArray[0] ? 1 : 0
            retValue += aLittleEndianBitArray[1] ? 2 : 0
            retValue += aLittleEndianBitArray[2] ? 4 : 0
            retValue += aLittleEndianBitArray[3] ? 8 : 0
            retValue += aLittleEndianBitArray[4] ? 16 : 0
            retValue += aLittleEndianBitArray[5] ? 32 : 0
            retValue += aLittleEndianBitArray[6] ? 64 : 0
            retValue += aLittleEndianBitArray[7] ? 128 : 0
        }
        
        self.init(retValue)
    }
}
