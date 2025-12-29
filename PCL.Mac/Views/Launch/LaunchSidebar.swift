//
//  LaunchSidebar.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/10.
//

import SwiftUI
import Core

struct LaunchSidebar: Sidebar {
    @ObservedObject private var router: AppRouter = .shared
    
    let width: CGFloat = 285
    
    var body: some View {
        MyText("LaunchSidebar")
        VStack(spacing: 11) {
            Spacer()
            MyButton("启动游戏", subLabel: "1.21.10", type: .highlight) {
                Task.detached {
                    let instance = try MinecraftInstance.load(from: URL(fileURLWithPath: "/tmp/versions/test"))
                    var options: LaunchOptions = .init()
                    options.runningDirectory = URL(fileURLWithPath: "/tmp/versions/test")
                    options.javaURL = URL(fileURLWithPath: "/usr/bin/java")
                    options.manifest = instance.manifest
                    options.memory = 4096
                    let launcher: MinecraftLauncher = .init(options: options)
                    let _ = try launcher.launch()
                }
            }
            .frame(height: 50)
            HStack(spacing: 11) {
                MyButton("实例选择") {
                    if let repository: MinecraftRepository = LauncherConfig.shared.minecraftRepositories.first {
                        router.append(.instanceList(repository))
                    } else {
                        router.append(.emptyInstanceList)
                    }
                }
                MyButton("实例设置") {
                    router.append(.instanceSettings)
                }
            }
            .frame(height: 32)
        }
        .padding(21)
    }
}
