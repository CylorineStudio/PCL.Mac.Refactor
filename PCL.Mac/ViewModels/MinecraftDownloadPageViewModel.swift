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
    @Published public var errorMessage: String?
    
    @discardableResult
    public func load(noCache: Bool = false) async throws -> VersionManifest {
        let manifest: VersionManifest = try await Requests.get("https://launchermeta.mojang.com/mc/game/version_manifest.json", noCache: noCache).decode(VersionManifest.self)
        CoreState.versionManifest = manifest
        
        await MainActor.run {
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
        return manifest
    }
    
    public func reload() {
        errorMessage = nil
        loaded = false
        Task {
            do {
                try await load(noCache: true)
                log("Minecraft 版本列表刷新成功")
            } catch {
                err("Minecraft 版本列表刷新失败：\(error.localizedDescription)")
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    public func destroy() {
        loaded = false
        latestRelease = nil
        latestSnapshot = nil
        versionMap = [:]
    }
}
