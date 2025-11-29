//
//  LaunchView.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/9.
//

import SwiftUI

struct LaunchView: View {
    @State private var text: String = ""
    
    var body: some View {
        MyText("LaunchView")
        TextField("聚焦测试", text: $text)
    }
}
