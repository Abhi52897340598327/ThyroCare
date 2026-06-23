//
//  LandingButton.swift
//  ThyroCare
//
//  Created by Abhiraam Venigalla on 5/26/26.
//

import SwiftUI

struct LandingButton: View {
    let title: String
    let action: () -> Void

    private let teal = Color(red: 0.06, green: 0.61, blue: 0.61)
    private let navy = Color(red: 0.01, green: 0.13, blue: 0.24)

    init(title: String, action: @escaping () -> Void = {}) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .font(.system(size: 25, weight: .regular))
                    .foregroundStyle(.white)

                HStack {
                    Spacer()

                    Image(systemName: "arrow.right")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(navy)
                        .frame(width: 46, height: 46)
                        .background(Circle().fill(Color.white))
                        .padding(.trailing, 10)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 74)
            .background(Capsule().fill(teal))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

#Preview {
    LandingButton(title: "Log In")
        .padding()
}
