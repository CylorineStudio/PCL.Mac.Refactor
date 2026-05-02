//
//  MinecraftDownloadPage.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2025/12/5.
//

import SwiftUI
import Core
import SwiftyJSON

struct MinecraftDownloadPage: View {
    @EnvironmentObject private var viewModel: MinecraftDownloadPageViewModel
    @StateObject private var loadingModel: MyLoadingViewModel = .init(text: "加载中")
    private static let dateFormatter: DateFormatter = {
        let formatter: DateFormatter = .init()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter
    }()
    
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
                        VersionView(latestRelease, description: "最新正式版，发布于 \(Self.dateFormatter.string(from: latestRelease.releaseTime))")
                        if let latestSnapshot = viewModel.latestSnapshot {
                            VersionView(latestSnapshot, description: "最新快照版，发布于  \(Self.dateFormatter.string(from: latestSnapshot.releaseTime))")
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func categoryCard(_ category: MinecraftVersion.VersionType) -> some View {
        let versions: [VersionManifest.Version] = viewModel.versionMap[category] ?? []
        MyCard("\(category.localizedName)（\(versions.count)）") {
            LazyVStack(spacing: 0) {
                ForEach(versions, id: \.id) { version in
                    VersionView(version, description: version.type == .aprilFool ? viewModel.aprilFoolVersionDescription(version.id) : Self.dateFormatter.string(from: version.releaseTime))
                }
            }
        }
    }
}

private struct VersionView: View {
    @EnvironmentObject private var viewModel: InstanceManager
    
    private static let dateFormatter: DateFormatter = {
        let formatter: DateFormatter = .init()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter
    }()
    private let version: VersionManifest.Version
    private let description: String
    
    init(_ version: VersionManifest.Version, description: String) {
        self.version = version
        self.description = description
    }
    
    var body: some View {
        MyListItem(.init(image: version.type.icon, name: version.id, description: description))
        .onTapGesture {
            AppRouter.shared.append(.minecraftInstallOptions(version: version))
        }
    }
}
