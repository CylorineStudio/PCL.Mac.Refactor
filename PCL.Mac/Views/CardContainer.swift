//
//  CardContainer.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2025/12/7.
//

import SwiftUI

struct CardContainer<Content: View>: View {
    @StateObject private var interactionState: CardInteractionState = .init()
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
        .environmentObject(interactionState)
    }
}

class CardInteractionState: ObservableObject {
    @Published private var value = false
    private let isStatic: Bool
    
    init(isStatic: Bool = false) {
        self.isStatic = isStatic
    }
    
    var isTransitioning: Bool {
        get { isStatic ? false : value }
        set {
            if !isStatic { value = newValue }
        }
    }
}
