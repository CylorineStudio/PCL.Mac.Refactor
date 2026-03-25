//
//  MinecraftInstallOptionsViewModel.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/2/13.
//

import Foundation
import Core

class MinecraftInstallOptionsViewModel: ObservableObject {
    @Published public var name: String { didSet { checkName() } }
    @Published public var loader: MinecraftInstallTask.Loader? {
        willSet { lastLoader = loader?.type }
        didSet {
            if let lastLoader, loader == nil {
                if name == "\(version.id)-\(lastLoader)" {
                    name = version.id
                    return
                }
            } else if let loader, lastLoader == nil {
                if name == version.id {
                    name = "\(version.id)-\(loader.type)"
                    return
                }
            } else if let loader, let lastLoader {
                if name == "\(version.id)-\(lastLoader)" {
                    name = "\(version.id)-\(loader.type)"
                    return
                }
            }
            checkName()
        }
    }
    @Published public var errorMessage: String?
    public let version: VersionManifest.Version
    private var lastLoader: ModLoader?
    
    init(version: VersionManifest.Version) {
        self.version = version
        self.name = version.id
        checkName()
    }
    
    private func checkName() {
        do {
            guard let repository: MinecraftRepository = InstanceManager.shared.currentRepository else {
                throw SimpleError("检查实例名失败：请先添加并选择一个游戏目录！")
            }
            _ = try repository.checkInstanceName(name, trim: false)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
