//
//  Frontend.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/11.
//

import Foundation
import Core

// 为 PCL.Mac.Core 中的一些枚举类扩展本地化名或图标，以在 SwiftUI 中显示。

extension MinecraftVersion.VersionType {
    var icon: String {
        switch self {
        case .release: "GrassBlock"
        case .snapshot: "Dirt"
        case .old: "Dirt"
        case .aprilFool: "Dirt"
        }
    }
    
    var name: String {
        switch self {
        case .release: "正式版"
        case .snapshot: "快照版"
        case .old: "远古版"
        case .aprilFool: "愚人节版"
        }
    }
}

extension SubTaskState {
    var image: String {
        switch self {
        case .waiting: "TaskWaiting"
        case .executing: ""
        case .finished: "TaskFinished"
        case .failed: ""
        }
    }
}

extension AccountType {
    public var localized: String {
        switch self {
        case .offline: "离线账号"
        case .microsoft: "正版账号"
        }
    }
}
