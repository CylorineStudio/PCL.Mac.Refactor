//
//  Sidebar.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/9.
//

import SwiftUI

protocol Sidebar: View {
    var width: CGFloat { get }
}

struct EmptySidebar: Sidebar {
    let width: CGFloat = 0
    
    var body: some View {
        EmptyView()
    }
}
