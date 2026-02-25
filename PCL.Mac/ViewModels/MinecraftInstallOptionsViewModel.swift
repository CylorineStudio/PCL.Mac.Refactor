//
//  MinecraftInstallOptionsViewModel.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/2/13.
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
        if name.isEmpty {
            errorMessage = "实例名不能为空！"
            return
        }
        let invalidCharacters: [Character] = [
            ":", ";", "/", "\\"
        ]
        if invalidCharacters.contains(where: name.contains(_:)) {
            errorMessage = "实例名包含特殊字符！"
            return
        }
        if let repository: MinecraftRepository = InstanceManager.shared.currentRepository,
           FileManager.default.fileExists(atPath: repository.versionsURL.appending(path: name).path) {
            errorMessage = "当前实例名已被使用！"
            return
        }
        errorMessage = nil
    }
}
