//
//  AppSettings.swift
//  iES
//
//  Created by Никита Пивоваров on 14.07.2024.
//

import Foundation
import SwiftUI

class AppSettings: ObservableObject {
    
    @Published var backgroundColor: Color = .black
    @Published var accentColor: Color = .purple
    
}
