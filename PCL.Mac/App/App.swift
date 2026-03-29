//
//  PCL_MacApp.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2025/11/8.
//

import SwiftUI

@main
struct PCL_MacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate: AppDelegate
    
    var body: some Scene {
        Settings { EmptyView() }
            .commands {
                CommandGroup(replacing: .appSettings) {
                    Button {
                        AppRouter.shared.setRoot(.settings)
                    } label: {
                        Label("设置", systemImage: "gear")
                    }
                    .keyboardShortcut(",", modifiers: [.command])
                }
                CommandMenu("导航") {
                    Button("返回") {
                        // 似乎无法使用 Escape 作为快捷键，这里只显示
                    }
                    .keyboardShortcut(.escape, modifiers: [])
                }
            }
        // 主视图声明被移至 AppWindow.swift:26
    }
}
