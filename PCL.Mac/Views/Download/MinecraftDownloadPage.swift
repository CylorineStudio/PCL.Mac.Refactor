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
    @EnvironmentObject private var viewModel: MinecraftDownloadPageViewModel
    
    var body: some View {
        CardContainer {
            if viewModel.loaded {
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
                try await viewModel.load()
            } catch {
                err("刷新版本清单失败：\(error.localizedDescription)")
                // TODO
            }
        }
    }
    
    var latestVersionsCard: some View {
        Group {
            if let latestRelease = viewModel.latestRelease {
                MyCard("最新版本", foldable: false) {
                    VStack(spacing: 0) {
                        VersionView(latestRelease, prefix: "最新正式版，更新于 ")
                        if let latestSnapshot = viewModel.latestSnapshot {
                            VersionView(latestSnapshot, prefix: "最新快照版，更新于 ")
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func categoryCard(_ category: MinecraftVersion.VersionType) -> some View {
        let versions: [VersionManifest.Version] = viewModel.versionMap[category] ?? []
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
    @EnvironmentObject private var viewModel: InstanceViewModel
    
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
        .onTapGesture {
            guard let repository = viewModel.currentRepository else {
                // TODO: Hint
                warn("试图安装 \(version.id)，但没有设置游戏仓库")
                return
            }
            let id: String = version.id
            let version: MinecraftVersion = .init(version.id)
            TaskManager.shared.execute(task: MinecraftInstallTask.create(name: id, version: version, repository: repository) {
                viewModel.switchInstance(id: id, version: version, repository)
            })
            AppRouter.shared.append(.tasks)
        }
    }
}
