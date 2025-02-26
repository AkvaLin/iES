//
//  SampleRate.swift
//  iES
//
//  Created by Никита Пивоваров on 10.01.2025.
//


import Foundation

enum SampleRate: Int, CaseIterable, SettingsEnum {
    case _12000Hz = 12000,
    _16000Hz = 16000,
    _22050Hz = 22050,
    _44100Hz = 44100
    
    var floatValue: Float { return Float(self.rawValue) }
    var doubleValue: Double { return Double(self.rawValue) }
    var ticksPerNodeTapBuffer: Int { return 6 }
    var nodeTapBufferCapacity: UInt32 { return UInt32(self.rawValue) / 10 }
    
    /// number of samples for a buffer of one tick length (1/60 second)
    var bufferCapacity: UInt32 { return UInt32(self.rawValue) / 60 }
    
    var friendlyName: String {
        switch self {
        case ._12000Hz: return "12"
        case ._16000Hz: return "16"
        case ._22050Hz: return "22"
        case ._44100Hz: return "44"
        }
    }
    
    var storedValue: Any { self.rawValue }
}
