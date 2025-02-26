//
//  Thinking2.swift
//  CoreSwiftUI
//
import SwiftUI

struct Thinking2: View {
    @State private var currentPhraseIndex = 0
    @State private var thinking: Bool = false
    private let dots = "..."
    
    var body: some View {
        VStack {
            Image(systemName: "gamecontroller")
                .font(.largeTitle)
                .phaseAnimator([false , true]) { ai, thinking in
                    ai
                        .symbolEffect(.wiggle.byLayer, value: thinking)
                        .symbolEffect(.bounce.byLayer, value: thinking)
                        .symbolEffect(.breathe.byLayer, value: thinking)
                }
            HStack(spacing: 0) {
                ForEach(Array(dots.enumerated()), id: \.offset) { index, letter in
                    Text(String(letter))
                        .font(.largeTitle)
                        .opacity(thinking ? 0 : 1)
                        .scaleEffect(thinking ? 1.5 : 1, anchor: .bottom)
                        .animation(
                            .easeInOut(duration: 0.5)
                            .delay(1)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) / 20),
                            value: thinking
                        
                        )
                }
            }
        }
        .foregroundStyle(Colors.accentColor)
        .onAppear {
            thinking = true
        }
    }
}


#Preview {
    Thinking2()
        .preferredColorScheme(.dark)
}
