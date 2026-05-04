//
//  Localizable.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2025/12/11.
//

import Foundation
import Core

// 为 PCL.Mac.Core 中的一些枚举类扩展本地化名或图标，以在 SwiftUI 中显示。

protocol Localizable {
    var localizedName: String { get }
}

extension MinecraftVersion.VersionType: Localizable {
    var icon: ImageResource {
        switch self {
        case .release: .iconGrassBlock
        case .snapshot: .iconDirt
        case .old: .iconCobblestone
        case .aprilFool: .iconGoldBlock
        }
    }
    
    var localizedName: String {
        switch self {
        case .release: "正式版"
        case .snapshot: "快照版"
        case .old: "远古版"
        case .aprilFool: "愚人节版"
        }
    }
}

extension ModrinthVersion.VersionType {
    var icon: ImageResource {
        switch self {
        case .release: .iconRelease
        case .beta: .iconBeta
        case .alpha: .iconAlpha
        }
    }
}

extension SubTaskState {
    var icon: ImageResource {
        switch self {
        case .waiting: .iconTaskWaiting
        case .executing: .iconTaskWaiting
        case .finished: .iconTaskFinished
        case .failed: .iconTaskFailed
        }
    }
}

extension AccountType: Localizable {
    var localizedName: String {
        switch self {
        case .offline: "离线账号"
        case .microsoft: "正版账号"
        case .yggdrasil: "第三方账号"
        }
    }
}

extension Account {
    var localizedTypeName: String {
        if let yggdrasilAccount = self as? YggdrasilAccount {
            return "\(yggdrasilAccount.authServer) 账号"
        }
        return type.localizedName
    }
}

extension ProjectType: Localizable {
    var localizedName: String {
        switch self {
        case .mod: "模组"
        case .modpack: "整合包"
        case .resourcepack: "资源包"
        case .shader: "光影包"
        }
    }
}

extension ModrinthVersion.VersionType: Localizable {
    var localizedName: String {
        switch self {
        case .release: "正式版"
        case .beta: "测试版"
        case .alpha: "早期测试版"
        }
    }
}

extension ModLoader {
    var icon: ImageResource {
        switch self {
        case .fabric: .iconFabric
        case .forge: .iconForge
        case .neoforge: .iconNeoforge
        }
    }
}
