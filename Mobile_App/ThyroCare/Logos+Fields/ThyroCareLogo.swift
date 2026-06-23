//
//  ThyroCareLogo.swift
//  ThyroCare
//
//  Created by Abhiraam Venigalla on 5/30/26.
//

import SwiftUI

struct ThyroCareLogo: View {
    var width: CGFloat
    var height: CGFloat
    
    init(width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
    }
    
    var body: some View {
        Image("ThyroCareLogo")
            .resizable()
            .scaledToFit()
            .frame(width: width, height: height)
    }
}

#Preview {
    ThyroCareLogo(width: 250.04, height: 467.9901)
    // lol
}
