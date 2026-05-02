//
//  MinecraftInstallOptionsViewModel.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/2/13.
//

import Foundation
import Core

@MainActor
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
    private let instanceManager: InstanceManager
    private var lastLoader: ModLoader?
    
    init(instanceManager: InstanceManager, version: VersionManifest.Version) {
        self.instanceManager = instanceManager
        self.version = version
        self.name = version.id
        checkName()
    }
    
    private func checkName() {
        do {
            _ = try instanceManager.currentRepository.checkInstanceName(name, trim: false)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
