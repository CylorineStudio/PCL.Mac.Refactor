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
                if currentPage == 0, let selectedVersionGroup = viewModel.selectedVersionGroup {
                    versionCard(versionGroup: selectedVersionGroup, isSelected: true, folded: false)
                }
                PaginatedContainer(versionList, id: \.0, currentPage: $currentPage, viewsPerPage: 10) { versionGroup in
                    versionCard(versionGroup: versionGroup, folded: versionList.count == 1 ? false : true)
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
                try await viewModel.load(selectedInstance: InstanceManager.shared.currentInstance)
            } catch {
                err("加载\(viewModel.project.type) \(viewModel.project.title) 版本列表失败：\(error.localizedDescription)")
                viewModel.loadingVM.fail(with: "加载版本列表失败：\(error.localizedDescription)")
            }
        }
    }
    
    private func onVersionTap(_ version: ProjectVersionModel) {
        log("\(version.name) \(version.version) 被点击")
        Task {
            guard let instance: MinecraftInstance = InstanceManager.shared.currentInstance else {
                hint("请先安装并选择一个实例！", type: .critical)
                return
            }
            
            do {
                try viewModel.checkInstance(instance, withVersion: version)
            } catch let error as ResourceInstallViewModel.InstanceCheckError {
                log("当前实例不满足该版本要求：\(error.localizedDescription)")
                switch error {
                case .versionUnsupported:
                    if await MessageBoxManager.shared.showText(
                        title: "当前实例不符合要求",
                        content: "\(error.localizedDescription)\n你可以选择继续安装，但游戏可能会发生崩溃或无法正常游玩。\n是否继续安装？",
                        level: .error,
                        .init(id: 0, label: "取消", type: .normal),
                        .init(id: 1, label: "继续", type: .red)
                    ) != 1 {
                        return
                    }
                default:
                    _ = await MessageBoxManager.shared.showText(
                        title: "当前实例不符合要求",
                        content: error.localizedDescription,
                        level: .error
                    )
                    return
                }
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
    
    @ViewBuilder
    private func versionCard(versionGroup: ResourceInstallViewModel.VersionGroup, isSelected: Bool = false, folded: Bool = true) -> some View {
        MyCard((isSelected ? "所选实例：" : "") + versionGroup.0.description, folded: folded) {
            let dependencies: [ProjectVersionModel.Dependency] = versionGroup.1[0].requiredDependencies
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
                ForEach(versionGroup.1) { version in
                    VersionListItemView(version: version)
                        .onTapGesture {
                            onVersionTap(version)
                        }
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
