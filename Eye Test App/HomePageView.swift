//
//  SwiftUIView.swift
//  Eye Test App
//
//  Created by Ammar Khan on 5/23/24.
//

import SwiftUI

struct HomePageView: View {
    @State private var isButtonPressed = false
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                // Additional UI components can be placed here

                NavigationLink(destination: EyeTest()) {
                    Text("Begin")
                        .padding()
                        .frame(minWidth: 100, maxWidth: .infinity)
                        .background(isButtonPressed ? Color.green : Color.blue)
                        .foregroundColor(.white)
                        .font(.title)
                        .cornerRadius(10)
                        .scaleEffect(isButtonPressed ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isButtonPressed)
                }
                .padding()
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.1).onEnded { _ in
                        self.isButtonPressed.toggle()
                        // This delay allows the animation to complete before navigation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            self.isButtonPressed = false
                        }
                    }
                )
                
                Spacer()
            }
            .navigationTitle("Home Page")
        }
    }
}
