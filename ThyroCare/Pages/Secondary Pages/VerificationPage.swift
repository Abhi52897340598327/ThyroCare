//
//  VerificationPage.swift
//  ThyroCare
//
//  Created by Abhiraam Venigalla on 6/15/26.
//

import SwiftUI

struct VerificationPage: View {
    @State private var code : Int = 0
    var body: some View {
        VStack {
            Text(Constants.verificationPageInstructions)
                .multilineTextAlignment(.center)
                .padding()
            OpenTextField("Code", $code)
                .padding()
            LandingButton(title: "Verify Code")
                .padding()
        }
    }
}

#Preview {
    VerificationPage()
}
