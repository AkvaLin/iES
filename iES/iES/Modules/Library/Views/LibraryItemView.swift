//
//  LibraryItemView.swift
//  iES
//
//  Created by Никита Пивоваров on 03.08.2024.
//

import SwiftUI

struct LibraryItemView: View {
    
    let icon: Image
    let title: String
    
    var body: some View {
        RoundedRectangle(cornerRadius: 25.0)
            .fill(.game.gradient)
            .aspectRatio(0.75, contentMode: .fit)
            .overlay {
                ZStack {
                    icon
                        .resizable()
                        .scaledToFill()
                }
            }
            .overlay {
                GeometryReader { proxy in
                    VStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: /*@START_MENU_TOKEN@*/25.0/*@END_MENU_TOKEN@*/)
                            .fill(.thinMaterial)
                            .frame(width: proxy.size.width * 0.80, height: proxy.size.height / 5)
                            .padding()
                            .overlay {
                                Text(title)
                                    .font(.title2)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: proxy.size.width * 0.80, maxHeight: proxy.size.height / 5, alignment: .center)
                            }
                    }
                    .frame(width: proxy.size.width)
                }
            }
            .clipped()
    }
}

#Preview {
    LibraryItemView(icon: Image(systemName: "gamecontroller"), title: "Game GameGameGameGameGameGame Game Game Game Game Game Game Game Game Game Game Game Game Game Game Game Game")
}
