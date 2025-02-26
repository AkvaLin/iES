//
//  Untitled.swift
//  iES
//
//  Created by Никита Пивоваров on 11.01.2025.
//

import SwiftUI

extension Image {
    init?(data: Data?) {
        guard let data,
              let uiImage = UIImage(data: data)
        else {
            return nil
        }
        self.init(uiImage: uiImage)
    }
}
