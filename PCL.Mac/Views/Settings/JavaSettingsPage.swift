//
//  JavaSettingsPage.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/3/6.
//

import SwiftUI
import Core

struct JavaSettingsPage: View {
    @StateObject private var viewModel: JavaSettingsViewModel = .init()
    
    var body: some View {
        CardContainer {
            MyCard("Java 列表", folded: false) {
                MyList(viewModel.javaList)
            }
        }
    }
}
