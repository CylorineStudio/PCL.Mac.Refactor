//
//  ResourceInstallPage.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/3/19.
//

import SwiftUI
import Core

struct ResourceInstallPage: View {
    @StateObject private var viewModel: ResourceInstallViewModel
    @State private var disableCardAppearAnimation: Bool = false
    @State private var currentPage: Int = 0
    
    init(project: ProjectListItemModel) {
        self._viewModel = StateObject(wrappedValue: .init(project: project))
    }
    
    var body: some View {
        CardContainer {
            MyCard("", titled: false) {
                ProjectListItemView(project: viewModel.project)
            }
            if viewModel.loaded, let versionList = viewModel.versionList {
                PaginatedContainer(versionList, id: \.0, currentPage: $currentPage, viewsPerPage: 10) { versions in
                    MyCard(versions.0.description) {
                        let dependencies: [ProjectVersionModel.Dependency] = versions.1[0].requiredDependencies
                        if !dependencies.isEmpty {
                            VStack(alignment: .leading) {
                                MyText("前置资源")
                                VStack(spacing: 0) {
                                    ForEach(dependencies) { dependency in
                                        ProjectListItemView(project: dependency.project)
                                            .onTapGesture {
                                                AppRouter.shared.append(.projectInstall(project: dependency.project))
                                            }
                                    }
                                }
                                MyText("版本列表")
                            }
                        }
                        VStack(spacing: 0) {
                            ForEach(versions.1) { version in
                                VersionListItemView(version: version)
                                    .onTapGesture {
                                        onVersionTap(version)
                                    }
                            }
                        }
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        disableCardAppearAnimation = true
                    }
                }
            } else {
                MyLoading(viewModel: viewModel.loadingVM)
                    .cardIndex(1)
            }
        }
        .task(id: viewModel.project) {
            do {
                try await viewModel.load()
            } catch {
                err("加载\(viewModel.project.type) \(viewModel.project.title) 版本列表失败：\(error.localizedDescription)")
                viewModel.loadingVM.fail(with: "加载版本列表失败：\(error.localizedDescription)")
            }
        }
    }
    
    private func onVersionTap(_ version: ProjectVersionModel) {
        Task {
            guard let instance: MinecraftInstance = InstanceManager.shared.currentInstance else {
                hint("请先安装并选择一个实例！", type: .critical)
                return
            }
            if await MessageBoxManager.shared.showText(
                title: "确认",
                content: "确定要安装 \(viewModel.project.title) \(version.version) 吗？",
                level: .info,
                .init(id: 0, label: "取消", type: .normal),
                .init(id: 1, label: "确定", type: .highlight)
            ) == 1 {
                do {
                    let task = try await viewModel.createInstallTask(forVersion: version, to: instance)
                    TaskManager.shared.execute(task: task)
                    AppRouter.shared.append(.tasks)
                }
            }
        }
    }
    
    private struct VersionListItemView: View {
        private let model: ListItem
        
        init(version: ProjectVersionModel) {
            self.model = .init(
                image: "\(version.type.rawValue.capitalized)Block",
                name: version.name,
                description: "\(version.version)，更新于\(version.datePublished)，\(version.type.localizedName)"
            )
        }
        
        var body: some View {
            MyListItem(model)
        }
    }
}
