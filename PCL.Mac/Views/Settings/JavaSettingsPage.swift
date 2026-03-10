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
            MyCard("", titled: false) {
                HStack {
                    MyButton("刷新 Java 列表") {
                        do {
                            try JavaManager.shared.research()
                        } catch {
                            err("刷新 Java 列表失败：\(error.localizedDescription)")
                            hint("刷新 Java 列表失败：\(error.localizedDescription)", type: .critical)
                        }
                        hint("刷新成功！", type: .finish)
                    }
                    .frame(width: 120)
                    MyButton("安装 Java") {
                        
                    }
                    Spacer()
                }
                .frame(height: 40)
            }
            
            MyCard("Java 列表", folded: false) {
                MyList(items: viewModel.javaList)
            }
            .cardIndex(1)
        }
    }
}
