//
//  LibraryItemView.swift
//  iES
//
//  Created by Никита Пивоваров on 03.08.2024.
//

import SwiftUI

struct LibraryItemView: View {
    
    let icon: Image?
    let title: String
    
    var body: some View {
        ZStack {
            if let icon {
                icon
                    .resizable()
                    .aspectRatio(0.75, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: Consts.buttonCornerRadius))
                icon
                    .resizable()
                    .aspectRatio(0.75, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: Consts.buttonCornerRadius))
                    .mask {
                        GeometryReader { proxy in
                            VStack {
                                Spacer()
                                RoundedRectangle(cornerRadius: Consts.buttonCornerRadius)
                                    .fill(.ultraThinMaterial)
                                    .frame(width: proxy.size.width * 0.80, height: proxy.size.height / 5)
                                    .padding()
                            }
                            .frame(width: proxy.size.width)
                        }
                    }
                    .blur(radius: 2)
                    .overlay {
                        GeometryReader { proxy in
                            VStack {
                                Spacer()
                                RoundedRectangle(cornerRadius: Consts.buttonCornerRadius)
                                    .fill(Colors.backgroundColor.opacity(0.5))
                                    .frame(width: proxy.size.width * 0.80, height: proxy.size.height / 5)
                                    .padding()
                                    .overlay {
                                        Text(title)
                                            .font(.title2)
                                            .multilineTextAlignment(.center)
                                            .frame(maxWidth: proxy.size.width * 0.80, maxHeight: proxy.size.height / 5, alignment: .center)
                                            .foregroundStyle(Colors.foregorundColor)
                                    }
                            }
                            .frame(width: proxy.size.width)
                        }
                    }
            } else {
                RoundedRectangle(cornerRadius: Consts.buttonCornerRadius)
                    .fill(Colors.primaryColor)
                    .aspectRatio(0.75, contentMode: .fit)
                    .overlay {
                        GeometryReader { proxy in
                            VStack {
                                Spacer()
                                Image(systemName: "gamecontroller")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundStyle(Colors.backgroundColor)
                                    .padding()
                                Spacer()
                                RoundedRectangle(cornerRadius: Consts.buttonCornerRadius)
                                    .fill(Colors.backgroundColor.opacity(0.5))
                                    .frame(width: proxy.size.width * 0.80, height: proxy.size.height / 5)
                                    .padding()
                                    .overlay {
                                        Text(title)
                                            .font(.title2)
                                            .multilineTextAlignment(.center)
                                            .frame(maxWidth: proxy.size.width * 0.80, maxHeight: proxy.size.height / 5, alignment: .center)
                                            .foregroundStyle(Colors.foregorundColor)
                                    }
                            }
                            .frame(width: proxy.size.width)
                        }
                    }
            }
        }
    }
}

#Preview {
    LibraryItemView(icon: Image(systemName: "gamecontroller"), title: "Game GameGameGameGameGameGame Game Game Game Game Game Game Game Game Game Game Game Game Game Game Game Game")
}
