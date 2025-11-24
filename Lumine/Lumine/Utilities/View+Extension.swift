//
//  View+Extension.swift
//  Lumine
//
//  Created by YoungK on 11/24/25.
//

import SwiftUI

extension View {
  func dimmedBlur() -> some View {
    self
      .blur(radius: 5)
      .overlay {
        Color.black.opacity(0.1)
      }
  }

  func dimmedBlur(_ isPresented: Binding<Bool>) -> some View {
    self
      .blur(radius: isPresented.wrappedValue ? 5 : 0)
      .overlay {
        if isPresented.wrappedValue {
          Color.black.opacity(0.1)
            //.ignoresSafeArea()
            .onTapGesture {
              withAnimation(.easeInOut(duration: 0.2)) {
                isPresented.wrappedValue = false
              }
            }
            .transition(.identity)
        }
      }
  }
}
