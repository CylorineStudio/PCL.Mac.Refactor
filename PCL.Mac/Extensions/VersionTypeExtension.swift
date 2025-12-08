//
//  VersionTypeExtension.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/7.
//

import Core

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
