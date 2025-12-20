//
//  MinecraftDownloadPage.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/5.
//

import SwiftUI
import Core
import SwiftyJSON

struct MinecraftDownloadPage: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var loaded: Bool = false
    @State private var latestRelease: VersionManifest.Version?
    @State private var latestSnapshot: VersionManifest.Version?
    @State private var categoryMap: [MinecraftVersion.VersionType: [VersionManifest.Version]] = [:]
    
    var body: some View {
        CardContainer {
            if loaded {
                latestVersionsCard
                categoryCard(.release)
                categoryCard(.snapshot)
                categoryCard(.old)
                categoryCard(.aprilFool)
            } else {
                MyText("正在加载版本列表")
            }
        }
        .onDisappear {
            loaded = false
            latestRelease = nil
            latestSnapshot = nil
            categoryMap = [:]
        }
        .task {
            do {
                let manifest: VersionManifest = try await refresh()
                await MainActor.run {
                    latestRelease = manifest.version(for: manifest.latestRelease)
                    if let latestSnapshot = manifest.latestSnapshot {
                        self.latestSnapshot = manifest.version(for: latestSnapshot)
                    }
                    categoryMap[.release] = manifest.versions.filter { $0.type == .release }
                    categoryMap[.snapshot] = manifest.versions.filter { $0.type == .snapshot }
                    categoryMap[.aprilFool] = manifest.versions.filter { $0.type == .aprilFool }
                    categoryMap[.old] = manifest.versions.filter { $0.type == .old }
                    loaded = true
                }
            } catch {
                err("刷新版本清单失败：\(error.localizedDescription)")
                // TODO
            }
        }
    }
    
    var latestVersionsCard: some View {
        Group {
            if let latestRelease {
                MyCard("最新版本", foldable: false) {
                    VStack(spacing: 0) {
                        VersionView(latestRelease, prefix: "最新正式版，更新于 ")
                        if let latestSnapshot {
                            VersionView(latestSnapshot, prefix: "最新快照版，更新于 ")
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func categoryCard(_ category: MinecraftVersion.VersionType) -> some View {
        let versions: [VersionManifest.Version] = categoryMap[category] ?? []
        MyCard("\(category.name)（\(versions.count)）") {
            LazyVStack(spacing: 0) {
                ForEach(versions, id: \.id) { version in
                    VersionView(version)
                }
            }
        }
    }
    
    private func refresh() async throws -> VersionManifest {
        let response = try await Requests.get("https://launchermeta.mojang.com/mc/game/version_manifest.json")
        if response.headers["Last-Modified"] == dataManager.versionsLastModified {
            return CoreState.versionManifest
        }
        await MainActor.run {
            dataManager.versionsLastModified = response.headers["Last-Modified"]
        }
        CoreState.versionManifest = try response.decode(VersionManifest.self)
        try response.data.write(to: AppURLs.cacheURL.appending(path: "version_manifest.json"))
        return CoreState.versionManifest
    }
}

private struct VersionView: View {
    private static let dateFormatter: DateFormatter = {
        let formatter: DateFormatter = .init()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter
    }()
    private let version: VersionManifest.Version
    private let prefix: String
    
    init(_ version: VersionManifest.Version, prefix: String = "") {
        self.version = version
        self.prefix = prefix
    }
    
    var body: some View {
        MyListItem {
            HStack {
                Image(version.type.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 35, height: 35)
                VStack(alignment: .leading) {
                    MyText(version.id)
                    MyText(prefix + Self.dateFormatter.string(from: version.releaseTime))
                }
                Spacer()
            }
        }
    }
}
