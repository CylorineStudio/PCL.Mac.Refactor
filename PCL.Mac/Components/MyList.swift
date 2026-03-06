//
//  MyList.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/1/26.
//

import SwiftUI

struct MyList: View {
    @State private var selected: Int?
    
    private let items: [ListItem]
    private let selectable: Bool
    private let onSelect: ((Int?) -> Void)?
    
    init(items: [ListItem], selectable: Bool = false, onSelect: ((Int?) -> Void)? = nil) {
        self.items = items
        self.selectable = onSelect != nil || selectable
        self.onSelect = onSelect
    }
    
    init(_ items: ListItem..., selectable: Bool = false, onSelect: ((Int?) -> Void)? = nil) {
        self.init(items: items, selectable: selectable, onSelect: onSelect)
    }
    
    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(0..<items.count, id: \.self) { index in
                MyListItem(items[index], selected: selected == index)
                    .onTapGesture {
                        guard selectable else { return }
                        selected = (selected == index ? nil : index)
                        onSelect?(selected)
                    }
            }
        }
        .animation(.easeOut(duration: 0.2), value: selected)
    }
}
