//
//  MyText.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/10.
//

import SwiftUI

struct MyText: View {
    private let text: String
    private let size: CGFloat
    private let color: Color
    
    init(_ text: String, size: CGFloat = 14, color: Color = .init(0x343D4A)) {
        self.text = text
        self.size = size
        self.color = color
    }
    
    var body: some View {
        Text(text)
            .font(.custom("PCLEnglish", size: size))
            .foregroundStyle(color)
    }
}
