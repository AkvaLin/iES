//
//  Filter.swift
//  iES
//
//  Created by Никита Пивоваров on 10.01.2025.
//


import Foundation

protocol Filter {
    mutating func step(x aX: Float32) -> Float32
}

/// First order filters are defined by the following parameters: y[n] = B0*x[n] + B1*x[n-1] - A1*y[n-1]
struct FirstOrderFilter: Filter {
    let B0: Float32
    let B1: Float32
    let A1: Float32
    var prevX: Float32
    var prevY: Float32
    
    mutating func step(x: Float32) -> Float32 {
        let y = (self.B0 * x) + (self.B1 * self.prevX) - (self.A1 * self.prevY)
        self.prevY = y
        self.prevX = x
        return y
    }
}

struct FilterChain: Filter {
    var filters: [Filter]
    
    mutating func step(x: Float32) -> Float32 {
        var x = x
        for i in 0 ..< self.filters.count
        {
            x = self.filters[i].step(x: x)
        }
        return x
    }
}
