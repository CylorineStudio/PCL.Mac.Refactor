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
    @ObservedObject private var dataManager: DataManager = .shared
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
        .task {
            do {
                var lastModified: String? = dataManager.versionsLastModified
                let response = try await Requests.get("https://launchermeta.mojang.com/mc/game/version_manifest.json")
                guard response.statusCode == 200 else {
                    throw SimpleError("服务器返回了错误的状态码：\(response.statusCode)")
                }
                if lastModified != response.headers["Last-Modified"] {
                    log("刷新版本清单成功")
                    lastModified = response.headers["Last-Modified"]
                }
                
                let manifest: VersionManifest = .init(json: try JSON(data: response.data))
                await MainActor.run {
                    self.dataManager.versionsLastModified = lastModified
                    self.latestRelease = manifest.getVersion(CoreState.versionManifest.latestRelease)
                    if let latestSnapshot = manifest.latestSnapshot {
                        self.latestSnapshot = manifest.getVersion(latestSnapshot)
                    }
                    self.categoryMap[.release] = manifest.versions.filter { $0.type == .release }
                    self.categoryMap[.snapshot] = manifest.versions.filter { $0.type == .snapshot }
                    self.categoryMap[.old] = manifest.versions.filter { $0.type == .old }
                    self.categoryMap[.aprilFool] = manifest.versions.filter { $0.type == .aprilFool }
                    self.loaded = true
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
