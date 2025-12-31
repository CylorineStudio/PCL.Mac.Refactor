//
//  LaunchSidebar.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/10.
//

import SwiftUI
import Core

struct LaunchSidebar: Sidebar {
    @EnvironmentObject private var instanceModel: InstanceViewModel
    @ObservedObject private var router: AppRouter = .shared
    
    let width: CGFloat = 285
    
    var body: some View {
        MyText("LaunchSidebar")
        VStack(spacing: 11) {
            Spacer()
            if let instance = instanceModel.currentInstance,
               let repository = instanceModel.currentRepository {
                MyButton("启动游戏", subLabel: instance.name, type: .highlight) {
                    Task.detached {
                        var options: LaunchOptions = .init()
                        options.runningDirectory = instance.runningDirectory
                        options.javaURL = URL(fileURLWithPath: "/usr/bin/java")
                        options.manifest = instance.manifest
                        options.repository = repository
                        options.memory = 4096
                        try options.validate()
                        let launcher: MinecraftLauncher = .init(options: options)
                        let _ = try launcher.launch()
                    }
                }
                .frame(height: 50)
            }
            HStack(spacing: 11) {
                MyButton("实例选择") {
                    if let repository: MinecraftRepository = instanceModel.currentRepository {
                        router.append(.instanceList(repository))
                    } else {
                        router.append(.noInstanceRepository)
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
