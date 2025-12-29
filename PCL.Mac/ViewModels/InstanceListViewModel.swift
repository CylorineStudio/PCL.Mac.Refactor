//
//  InstanceListViewModel.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/29.
//

import SwiftUI
import Core

class InstanceListViewModel: ObservableObject {
    @Published public var repositories: [MinecraftRepository] = LauncherConfig.shared.minecraftRepositories
    
    public func addRepository(url: URL) {
        let repository: MinecraftRepository = .init(name: "自定义目录", url: url)
        repositories.append(repository)
        LauncherConfig.shared.minecraftRepositories.append(repository)
    }
}
