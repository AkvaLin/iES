//
//  FlipView.swift
//  iES
//
//  Created by Никита Пивоваров on 06.02.2025.
//


import SwiftUI

struct FlipView<FrontView: View, BackView: View>: View {

      let frontView: FrontView
      let backView: BackView

      @Binding var showBack: Bool

      var body: some View {
          ZStack() {
                frontView
                  .modifier(FlipOpacity(percentage: showBack ? 0 : 1))
                  .rotation3DEffect(Angle.degrees(showBack ? 180 : 360), axis: (0,1,0))
                backView
                  .modifier(FlipOpacity(percentage: showBack ? 1 : 0))
                  .rotation3DEffect(Angle.degrees(showBack ? 0 : 180), axis: (0,1,0))
          }
      }
}

private struct FlipOpacity: AnimatableModifier {
   var percentage: CGFloat = 0
   
   var animatableData: CGFloat {
      get { percentage }
      set { percentage = newValue }
   }
   
   func body(content: Content) -> some View {
      content
           .opacity(Double(percentage.rounded()))
   }
}
