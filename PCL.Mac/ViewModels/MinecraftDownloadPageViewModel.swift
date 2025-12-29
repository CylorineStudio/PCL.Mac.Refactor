//
//  MinecraftDownloadPageViewModel.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/29.
//

import SwiftUI
import Core

class MinecraftDownloadPageViewModel: ObservableObject {
    @Published public var loaded: Bool = false
    @Published public var latestRelease: VersionManifest.Version?
    @Published public var latestSnapshot: VersionManifest.Version?
    @Published public var versionMap: [MinecraftVersion.VersionType: [VersionManifest.Version]] = [:]
    public var lastModified: String?
    
    @discardableResult
    public func refresh() async throws -> VersionManifest {
        let response = try await Requests.get("https://launchermeta.mojang.com/mc/game/version_manifest.json")
        let remoteLastModified: String? = response.headers["Last-Modified"]
        if remoteLastModified == nil || remoteLastModified != lastModified {
            CoreState.versionManifest = try response.decode(VersionManifest.self)
            try response.data.write(to: AppURLs.cacheURL.appending(path: "version_manifest.json"))
        }
        
        await MainActor.run {
            autoreleasepool { // 防止 copy-on-write 对 Optional 不生效
                let manifest: VersionManifest = CoreState.versionManifest
                lastModified = remoteLastModified
                latestRelease = manifest.version(for: manifest.latestRelease)
                if let latestSnapshot = manifest.latestSnapshot {
                    self.latestSnapshot = manifest.version(for: latestSnapshot)
                }
                versionMap[.release] = manifest.versions.filter { $0.type == .release }
                versionMap[.snapshot] = manifest.versions.filter { $0.type == .snapshot }
                versionMap[.aprilFool] = manifest.versions.filter { $0.type == .aprilFool }
                versionMap[.old] = manifest.versions.filter { $0.type == .old }
                loaded = true
            }
        }
        return CoreState.versionManifest
    }
    
    public func destroy() {
        
    }
}
