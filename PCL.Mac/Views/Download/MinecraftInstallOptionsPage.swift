//
//  MinecraftInstallOptionsPage.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/2/11.
//

import SwiftUI
import Core

struct MinecraftInstallOptionsPage: View {
    @StateObject private var viewModel: MinecraftInstallOptionsViewModel
    @EnvironmentObject private var instanceVM: InstanceManager
    
    init(version: VersionManifest.Version) {
        self._viewModel = .init(wrappedValue: .init(version: version))
    }
    
    var body: some View {
        CardContainer {
            VStack {
                MyCard("", titled: false, limitHeight: false) {
                    HStack {
                        Image(icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .padding(.trailing, 12)
                        VStack(alignment: .leading) {
                            if let errorMessage = viewModel.errorMessage {
                                MyText(errorMessage, color: .red)
                            }
                            MyTextField(text: $viewModel.name)
                            .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 15)
                VStack(spacing: 6) {
                    ModLoaderCard(.fabric, viewModel.version.id, $viewModel.loader)
                        .cardIndex(1)
                    ModLoaderCard(.forge, viewModel.version.id, $viewModel.loader)
                        .cardIndex(2)
                }
                Spacer()
            }
            .padding(EdgeInsets(top: 10, leading: 25, bottom: 25, trailing: 25))
        }
        .overlay(alignment: .bottom) {
            MyExtraTextButton(image: "DownloadPageIcon", imageSize: 20, text: "开始下载") {
                if let errorMessage = viewModel.errorMessage {
                    hint(errorMessage, type: .critical)
                    return
                }
                guard let repository = instanceVM.currentRepository else {
                    warn("试图安装 \(viewModel.version)，但没有设置游戏仓库")
                    hint("请先添加一个游戏目录！", type: .critical)
                    return
                }
                let version: MinecraftVersion = .init(viewModel.version.id)
                TaskManager.shared.execute(task: MinecraftInstallTask.create(name: viewModel.name, version: version, repository: repository, modLoader: viewModel.loader) { instance in
                    instanceVM.switchInstance(to: instance, repository)
                    if AppRouter.shared.getLast() == .tasks {
                        AppRouter.shared.removeLast()
                        if case .minecraftInstallOptions = AppRouter.shared.getLast() {
                            AppRouter.shared.removeLast()
                        }
                    }
                })
                AppRouter.shared.append(.tasks)
            }
            .padding()
        }
        .animation(.spring(duration: 0.2), value: viewModel.errorMessage)
    }
    
    private var icon: String {
        if let loader = viewModel.loader {
            return switch loader.type {
            case .fabric: "Fabric"
            case .forge: "Forge"
            }
        } else {
            return viewModel.version.type == .snapshot ? "Dirt" : "GrassBlock"
        }
    }
}

private struct ModLoaderCard: View {
    @Binding private var currentLoader: MinecraftInstallTask.Loader?
    @State private var versions: [Version]?
    @State private var loadState: LoadState = .loading
    private let type: ModLoader
    private let minecraftVersion: String
    
    init(_ type: ModLoader, _ minecraftVersion: String, _ currentLoader: Binding<MinecraftInstallTask.Loader?>) {
        self.type = type
        self.minecraftVersion = minecraftVersion
        self._currentLoader = currentLoader
    }
    
    var body: some View {
        MyCard("", titled: false, limitHeight: false, padding: 0) {
            ZStack(alignment: .topLeading) {
                MyCard(type.description, foldable: loadState == .finished, folded: true) {
                    if let versions {
                        MyList(versions.map { ListItem(image: iconName, name: $0.id, description: $0.beta ? "测试版" : "稳定版") }) { index in
                            if let index {
                                currentLoader = MinecraftInstallTask.Loader(type: type, version: versions[index].id)
                            } else {
                                currentLoader = nil
                            }
                        }
                    }
                }
                .disableCardAppearAnimation()
                HStack(spacing: 7) {
                    if let currentLoader, currentLoader.type == type {
                        Image(iconName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18)
                        MyText(currentLoader.version, color: .colorGray1)
                    } else {
                        MyText(loadState.description, color: .colorGray4)
                    }
                }
                .padding(.leading, 300)
                .padding(.top, 10)
                .allowsHitTesting(false)
            }
        }
        .task(id: type) {
            await loadVersions()
        }
    }
    
    private var iconName: String {
        switch type {
        case .fabric: "Fabric"
        case .forge: "Forge"
        }
    }
    
    private func loadVersions() async {
        do {
            let versions: [Version] = switch type {
            case .fabric:
                try await Requests.get("https://meta.fabricmc.net/v2/versions/loader/\(minecraftVersion)").json().arrayValue
                    .map { .init(id: $0["loader"]["version"].stringValue) }
            case .forge:
                try await Requests.get("https://bmclapi2.bangbang93.com/forge/minecraft/\(minecraftVersion)").json().arrayValue
                    .map { .init(id: $0["version"].stringValue) }
            }
            await MainActor.run {
                self.versions = versions.sorted { $0.id.compare($1.id, options: .numeric) == .orderedDescending }
                loadState = versions.isEmpty ? .noUsableVersion : .finished
            }
        } catch {
            err("加载 \(type) 版本列表失败：\(error.localizedDescription)")
            await MainActor.run {
                loadState = .error(message: error.localizedDescription)
            }
        }
    }
    
    private enum LoadState: Equatable, CustomStringConvertible {
        case loading
        case noUsableVersion
        case error(message: String)
        case finished
        
        var description: String {
            switch self {
            case .loading: "加载中"
            case .noUsableVersion: "无可用版本"
            case .error(let message): "加载失败：\(message)"
            case .finished: "可以添加"
            }
        }
    }
    
    private struct Version {
        public let id: String
        public let beta: Bool
        
        public init(id: String) {
            self.id = id
            // 稳定版判断逻辑：https://github.com/PCL-Community/PCL2-CE/blob/45773cb9c69e677a3ae334c3d1f55f08468d623a/Plain%20Craft%20Launcher%202/Modules/Minecraft/ModDownload.vb#L1047
            self.beta = id.contains("alpha")
        }
    }
}
