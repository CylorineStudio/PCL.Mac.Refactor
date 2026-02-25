//
//  MyList.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/26.
//

import SwiftUI

struct MyList: View {
    private let items: [ListItem]
    private let onSelect: ((Int?) -> Void)?
    @State private var selected: Int?
    
    init(_ items: [ListItem], onSelect: ((Int?) -> Void)? = nil) {
        self.items = items
        self.onSelect = onSelect
    }
    
    init(_ items: ListItem..., onSelect: ((Int?) -> Void)? = nil) {
        self.items = items
        self.onSelect = onSelect
    }
    
    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(0..<items.count, id: \.self) { index in
                MyListItem(items[index], selected: selected == index)
                    .onTapGesture {
                        selected = (selected == index ? nil : index)
                        onSelect?(selected)
                    }
            }
        }
        .animation(.easeOut(duration: 0.2), value: selected)
    }
}
