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
    private let loadingModel: MyLoadingViewModel = .init(text: "加载中")
    
    var body: some View {
        CardContainer {
            if viewModel.loaded {
                latestVersionsCard
                categoryCard(.release)
                    .cardIndex(1)
                categoryCard(.snapshot)
                    .cardIndex(2)
                categoryCard(.old)
                    .cardIndex(3)
                categoryCard(.aprilFool)
                    .cardIndex(4)
            } else {
                MyLoading(viewModel: loadingModel)
            }
        }
        .onAppear {
            viewModel.reload()
        }
        .onChange(of: viewModel.errorMessage) { errorMessage in
            if let errorMessage {
                loadingModel.fail(with: "加载失败：\(errorMessage)")
            } else {
                loadingModel.reset()
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
        MyListItem(.init(image: .init(named: version.type.icon), name: version.id, description: prefix + Self.dateFormatter.string(from: version.releaseTime)))
        .onTapGesture {
            guard let repository = viewModel.currentRepository else {
                warn("试图安装 \(version.id)，但没有设置游戏仓库")
                hint("请先添加一个游戏目录！", type: .critical)
                return
            }
            let id: String = version.id
            let version: MinecraftVersion = .init(version.id)
            TaskManager.shared.execute(task: MinecraftInstallTask.create(name: id, version: version, repository: repository) { instance in
                viewModel.switchInstance(to: instance, repository)
                if AppRouter.shared.getLast() == .tasks {
                    AppRouter.shared.removeLast()
                }
            })
            AppRouter.shared.append(.tasks)
        }
    }
}
