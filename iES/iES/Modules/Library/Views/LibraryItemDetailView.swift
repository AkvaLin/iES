//
//  LibraryItemDetailView.swift
//  iES
//
//  Created by Никита Пивоваров on 30.08.2024.
//

import SwiftUI

struct LibraryItemDetailView: View {
    
    @Environment(\.colorScheme) var colorScheme
    let model: LibraryItemModel
    
    var body: some View {
        Group {
            if colorScheme == .dark {
                Rectangle()
                    .fill(.black.gradient)
            } else {
                Rectangle()
                    .fill(.white.gradient)
            }
        }
        .overlay {
            VStack {
                HStack {
                    contentView
                    divier
                    rightMenuBar
                }
                playButton
            }
            .padding()
        }
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .aspectRatio(1, contentMode: .fit)
        .shadow(color: colorScheme == .dark ? .gray.opacity(0.33) : .black.opacity(0.33), radius: 10)
        .padding()
    }
    
    private var contentView: some View {
        VStack {
            Text(model.title)
                .lineLimit(3)
                .font(.largeTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
            model.icon
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(.vertical)
        }
        .padding()
    }
    
    private var divier: some View {
        Rectangle()
            .fill(.accent)
            .frame(maxWidth: 1, maxHeight: .infinity)
            .padding(.vertical)
    }
    
    private var rightMenuBar: some View {
        VStack {
            Button {
                
            } label: {
                Image(systemName: "gear")
            }
            .frame(minWidth: 44, minHeight: 44)
            .padding(.top, 25)
            Spacer()
            Button {
                
            } label: {
                Image(systemName: "chart.bar.xaxis")
            }
            .frame(minWidth: 44, minHeight: 44)
            Spacer()
            Button {
                
            } label: {
                Image(systemName: "trash")
            }
            .frame(minWidth: 44, minHeight: 44)
            .padding(.bottom, 25)
        }
        .font(.title)
        .padding()
    }
    
    private var playButton: some View {
        Button {
            
        } label: {
            Text("Play")
                .font(.largeTitle)
                .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
                .padding()
        }
        .buttonStyle(.borderedProminent)
        .padding()
    }
}

#Preview {
    LibraryItemDetailView(model: .init(title: "Some Title", icon: Image(systemName: "house")))
}
