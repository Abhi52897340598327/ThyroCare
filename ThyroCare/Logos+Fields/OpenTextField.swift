//
//  OpenTextField.swift
//  ThyroCare
//
//  Created by Abhiraam Venigalla on 5/30/26.
//

import SwiftUI
import UIKit

struct OpenTextField: View {
    let title: String
    @Binding private var text: String
    private let keyboardType: UIKeyboardType

    init(title: String, text: Binding<String>) {
        self.title = title
        self._text = text
        self.keyboardType = .default
    }

    init(_ title: String, _ text: Binding<String>) {
        self.init(title: title, text: text)
    }

    init(title: String, text number: Binding<Int>) {
        self.title = title
        self._text = Binding(
            get: { String(number.wrappedValue) },
            set: { newValue in
                let digitsOnly = newValue.filter { $0.isNumber }
                number.wrappedValue = Int(digitsOnly) ?? 0
            }
        )
        self.keyboardType = .numberPad
    }

    init(_ title: String, _ number: Binding<Int>) {
        self.init(title: title, text: number)
    }

    var body: some View {
        TextField(title, text: $text)
            .keyboardType(keyboardType)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding()
            .background(Color.gray.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    @Previewable @State var username = ""
    @Previewable @State var numberCode = 0

    OpenTextField(title: "Username", text: $username)
        .padding()
    OpenTextField(title: "Number Code", text: $numberCode)
        .padding()
}
