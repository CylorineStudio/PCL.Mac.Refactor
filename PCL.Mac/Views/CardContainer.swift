//
//  CardContainer.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/7.
//

import SwiftUI

struct CardContainer<Content: View>: View {
    private let content: () -> Content
    
    init(@ViewBuilder _ content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                content()
            }
            .frame(maxWidth: .infinity)
            .padding(24)
        }
    }
}
