//
//  LaunchSidebar.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/10.
//

import SwiftUI
import Core

struct LaunchSidebar: Sidebar {
    @EnvironmentObject private var instanceViewModel: InstanceViewModel
    @ObservedObject private var router: AppRouter = .shared
    
    let width: CGFloat = 285
    
    var body: some View {
        MyText("LaunchSidebar")
        VStack(spacing: 11) {
            Spacer()
            Group {
                if let instance = instanceViewModel.currentInstance,
                   let repository = instanceViewModel.currentRepository {
                    MyButton("启动游戏", subLabel: instance.name, type: .highlight) {
                        instanceViewModel.launch(instance, in: repository)
                    }
                } else {
                    MyButton("下载游戏", subLabel: "未找到可用的游戏实例", type: .normal) {
                        router.setRoot(.download)
                    }
                }
            }
            .frame(height: 50)
            HStack(spacing: 11) {
                MyButton("实例选择") {
                    if let repository: MinecraftRepository = instanceViewModel.currentRepository {
                        router.append(.instanceList(repository))
                    } else {
                        router.append(.noInstanceRepository)
                    }
                }
                if let _ = instanceViewModel.currentInstance {
                    MyButton("实例设置") {
                        router.append(.instanceSettings)
                    }
                }
            }
            .frame(height: 32)
        }
        .padding(21)
    }
}
