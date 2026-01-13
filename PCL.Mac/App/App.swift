//
//  PCL_MacApp.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/8.
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
            }
        // 主视图声明被移至 AppWindow.swift:26
    }
}
