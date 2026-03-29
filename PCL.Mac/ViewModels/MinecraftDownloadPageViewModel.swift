//
//  MinecraftDownloadPageViewModel.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2025/12/29.
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
        let response = try await Requests.get("https://launchermeta.mojang.com/mc/game/version_manifest.json", noCache: noCache)
        let manifest: VersionManifest = try response.decode(VersionManifest.self)
        CoreState.versionManifest = manifest
        do {
            try response.data.write(to: URLConstants.cacheURL.appending(path: "version_manifest.json"))
        } catch {
            err("保存版本列表缓存失败：\(error.localizedDescription)")
        }
        
        
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
    
    public func aprilFoolVersionDescription(_ id: String) -> String {
        switch id.lowercased() {
        case "15w14a": "2015 | 作为一款全年龄向的游戏，我们需要和平，需要爱与拥抱。"
        case "1.rv-pre1": "2016 | 是时候将现代科技带入 Minecraft 了！"
        case "3d shareware v1.34": "2019 | 我们从地下室的废墟里找到了这个开发于 1994 年的杰作！"
        case "20w14infinite": "2020 | 我们加入了 20 亿个新的维度，让无限的想象变成了现实！"
        case "22w13oneblockatatime": "2022 | 一次一个方块更新！迎接全新的挖掘、合成与骑乘玩法吧！"
        case "23w13a_or_b": "2023 | 研究表明：玩家喜欢作出选择——越多越好！"
        case "24w14potato": "2024 | 毒马铃薯一直都被大家忽视和低估，于是我们超级加强了它！"
        case "25w14craftmine": "2025 | 你可以合成任何东西——包括合成你的世界！"
        default: "20?? | ???"
        }
    }
}
