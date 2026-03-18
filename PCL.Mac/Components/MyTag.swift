//
//  MyTag.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/3/18.
//

import SwiftUI

struct MyTag: View {
    private let label: String
    private let labelColor: Color
    private let backgroundColor: Color
    private let size: CGFloat
    
    init(_ label: String, labelColor: Color = .color1, backgroundColor: Color = .white, size: CGFloat = 14) {
        self.label = label
        self.labelColor = labelColor
        self.backgroundColor = backgroundColor
        self.size = size
    }
    
    var body: some View {
        MyText(label, size: size, color: labelColor)
            .padding(2)
            .background {
                RoundedRectangle(cornerRadius: 5)
                    .fill(backgroundColor)
            }
    }
}
