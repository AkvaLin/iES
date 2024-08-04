//
//  HomeViewIcon.swift
//  iES
//
//  Created by Никита Пивоваров on 03.08.2024.
//

import SwiftUI

struct HomeViewIcon: View {
    
    private let localizedText: LocalizedStringKey
    private var text: String
    private let color: Color
    private var icon: Image?
    private let isEmpty: Bool
    
    public init(localizedText: LocalizedStringKey, color: Color, icon: Image) {
        self.localizedText = localizedText
        self.text = ""
        self.color = color
        self.icon = icon
        self.isEmpty = false
    }
    
    public init(text: String, color: Color, icon: Image) {
        self.text = text
        self.localizedText = ""
        self.color = color
        self.icon = icon
        self.isEmpty = false
    }
    
    /// create empty circle
    public init() {
        self.localizedText = ""
        self.text = ""
        self.color = .clear
        self.icon = nil
        self.isEmpty = true
    }
    
    var body: some View {
        Circle()
            .fill(color.gradient)
            .shadow(radius: 10)
            .overlay {
                GeometryReader { proxy in
                    VStack {
                        Spacer()
                        if let icon {
                            icon
                                .resizable()
                                .scaledToFit()
                                .frame(height: proxy.size.height / 2)
                                .padding([.top, .horizontal])
                        }
                        if !isEmpty {
                            RoundedRectangle(cornerRadius: 25.0)
                                .fill(.thinMaterial)
                                .frame(height: proxy.size.height / 4)
                                .padding()
                                .shadow(radius: 10)
                                .overlay {
                                    Group {
                                        if localizedText != "" {
                                            Text(localizedText)
                                        } else {
                                            Text(text)
                                        }
                                    }
                                    .font(.title)
                                    .bold()
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: proxy.size.width * 0.80, maxHeight: proxy.size.height / 4, alignment: .center)
                                }
                        }
                    }
                }
            }
    }
}

#Preview {
    HomeViewIcon(localizedText: "Home", color: .green, icon: .init(systemName: "house"))
}
