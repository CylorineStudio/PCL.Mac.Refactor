//
//  MySearchBox.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/3/16.
//

import SwiftUI

struct MySearchBox: View {
    @State private var query: String = ""
    @FocusState private var focused: Bool
    private let placeholder: String
    private let onSubmit: (String) -> Void
    
    init(placeholder: String, onSubmit: @escaping (String) -> Void) {
        self.placeholder = placeholder
        self.onSubmit = onSubmit
    }
    
    var body: some View {
        MyCard("", titled: false) {
            HStack {
                Image("IconSearch")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(Color.color1)
                
                ZStack(alignment: .leading) {
                    TextField("", text: $query)
                        .textFieldStyle(.plain)
                        .foregroundStyle(Color.color1)
                    if !focused && query.isEmpty {
                        Text(placeholder)
                            .allowsHitTesting(false)
                            .foregroundStyle(Color.colorGray3)
                    }
                }
                .font(.custom("PCLEnglish", size: 16))
                .focused($focused)
                .onChange(of: query) { _ in
                    if query.count > 50 {
                        query = String(query.prefix(50))
                    }
                }
                .onSubmit {
                    focused = false
                    onSubmit(query)
                }
            }
        }
        .frame(height: 40)
    }
}
