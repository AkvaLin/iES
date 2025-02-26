//
//  ProfileView.swift
//  iES
//
//  Created by Никита Пивоваров on 14.07.2024.
//

import SwiftUI

struct ProfileView: View {
    
    var body: some View {
        ZStack {
            UIElements.background()
        }
        .navigationTitle(Localization.profile)
    }
}

#if DEBUG
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ProfileView()
                .previewDevice(PreviewDevice(rawValue: "iPhone 15 Pro"))
                .previewDisplayName("iPhone")
            ProfileView()
                .previewDevice(PreviewDevice(rawValue: "iPad Pro 13-inch (M4)"))
                .previewDisplayName("iPad")
        }
        .previewInterfaceOrientation(.landscapeLeft)
    }
}
#endif
