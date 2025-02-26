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
    private var icon: Image?
    private let isEmpty: Bool
    private let isSystem: Bool
    
    public init(localizedText: LocalizedStringKey, icon: Image) {
        self.localizedText = localizedText
        self.text = ""
        self.icon = icon
        self.isEmpty = false
        self.isSystem = true
    }
    
    public init(text: String, icon: Image) {
        self.text = text
        self.localizedText = ""
        self.icon = icon
        self.isEmpty = false
        self.isSystem = false
    }
    
    /// create empty circle
    public init() {
        self.localizedText = ""
        self.text = ""
        self.icon = nil
        self.isEmpty = true
        self.isSystem = true
    }
    
    var body: some View {
        Circle()
            .fill(isEmpty || !isSystem ? Color.clear.gradient : Gradients.primaryGradient)
            .shadow(radius: 10)
            .overlay {
                GeometryReader { proxy in
                    if !isSystem, let icon {
                        ZStack {
                            icon
                                .resizable()
                                .scaledToFill()
                                .frame(width: proxy.size.width, height: proxy.size.height)
                                .foregroundStyle(Colors.backgroundColor)
                                .clipShape(.circle)
                            VStack {
                                Spacer()
                                title(proxy: proxy)
                            }
                        }
                    } else {
                        VStack {
                            Spacer()
                            if !isEmpty {
                                (icon ?? Image(systemName: "gamecontroller"))
                                    .resizable()
                                    .scaledToFit()
                                    .padding()
                                    .frame(height: proxy.size.height / 2)
                                    .clipShape(RoundedRectangle(cornerRadius: Consts.buttonCornerRadius))
                                    .padding([.top, .horizontal])
                                    .foregroundStyle(Colors.backgroundColor)
                            }
                            if !isEmpty {
                                title(proxy: proxy)
                            }
                        }
                    }
                }
            }
    }
    
    private func title(proxy: GeometryProxy) -> some View {
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
            .foregroundStyle(Colors.foregorundColor)
    }
}

#Preview {
    HomeViewIcon(localizedText: "Home", icon: .init(systemName: "house"))
}
