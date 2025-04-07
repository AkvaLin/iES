//
//  YandexAuthView.swift
//  iES
//
//  Created by Никита Пивоваров on 05.04.2025.
//

import SwiftUI
import WebKit

struct YandexAuthView: UIViewControllerRepresentable {
    typealias UIViewControllerType = YandexAuthViewController
    
    func makeUIViewController(context: Context) -> YandexAuthViewController {
        return YandexAuthViewController()
    }
    
    func updateUIViewController(_ uiViewController: YandexAuthViewController, context: Context) { }
}
