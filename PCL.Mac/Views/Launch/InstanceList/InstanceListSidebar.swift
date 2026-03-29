//
//  InstanceListSidebar.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2025/12/27.
//

import SwiftUI
import Core

struct InstanceListSidebar: Sidebar {
    @EnvironmentObject private var instanceViewModel: InstanceManager
    @EnvironmentObject private var viewModel: InstanceListViewModel
    
    let width: CGFloat = 300
    private let modpackViewModel: ModpackViewModel = .init()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !instanceViewModel.repositories.isEmpty {
                MyText("目录列表", size: 12, color: .colorGray3)
                    .padding(.leading, 13)
                    .padding(.top, 18)
                MyNavigationList(
                    routeList: instanceViewModel.repositories.map({ .init(AppRoute.instanceList($0), nil, $0.name) })
                ) { route in
                    if case .instanceList(let repository) = route {
                        viewModel.reloadAsync(repository)
                    }
                }
            }
            MyText("添加或导入", size: 12, color: .colorGray3)
                .padding(.leading, 13)
                .padding(.top, 18)
            VStack(spacing: 0) {
                ImportButton("IconAdd", "添加已有目录") {
                    try instanceViewModel.requestAddRepository()
                }
                ImportButton("IconImportModpack", "导入整合包", perform: onImportModpackClicked)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: instanceViewModel.repositories) { newValue in
            if let repository = newValue.first, AppRouter.shared.getLast() == .noInstanceRepository {
                AppRouter.shared.removeLast()
                AppRouter.shared.append(.instanceList(repository))
            }
        }
    }
    
    private func onImportModpackClicked() {
        guard let repository: MinecraftRepository = instanceViewModel.currentRepository else {
            hint("请先选择一个游戏目录！", type: .critical)
            return
        }
        
        let panel: NSOpenPanel = .init()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [
            .zip,
            .init(filenameExtension: "mrpack")!
        ]
        
        if panel.runModal() == .OK {
            guard let url = panel.url else { return }
            Task.detached {
                await importModpack(url, repository: repository)
            }
        }
    }
    
    private func importModpack(_ url: URL, repository: MinecraftRepository) async {
        do {
            guard let result: ModpackViewModel.ModpackLoadResult = try modpackViewModel.loadModpack(at: url) else {
                _ = await MessageBoxManager.shared.showTextAsync(
                    title: "不支持的整合包格式",
                    content: "很抱歉，PCL.Mac 目前只支持导入 Modrinth 格式的整合包，不支持这个整合包使用的格式……",
                    level: .error
                )
                return
            }
            guard await MessageBoxManager.shared.showTextAsync(
                title: "整合包信息",
                content: "格式：\(result.format)\n名称：\(result.name)\n版本：\(result.version)\n描述：\(result.summary)\n依赖：\(result.dependencyInfo)\n\n是否继续安装？",
                level: .info,
                .no(),
                .yes(label: "继续")
            ) == 1 else { return }
            
            guard var name: String = await MessageBoxManager.shared.showInputAsync(
                title: "导入整合包 - 输入实例名",
                initialContent: result.name
            ) else { return }
            
            do {
                name = try repository.checkInstanceName(name)
            } catch {
                hint("该名称不可用：\(error.localizedDescription)", type: .critical)
                return
            }
            
            switch result.index {
            case .modrinth(let index):
                let task = try ModrinthModpackInstallTask.create(
                    url: url,
                    index: index,
                    repository: repository,
                    name: name
                ) { instance in
                    instanceViewModel.switchInstance(to: instance, repository)
                    if AppRouter.shared.getLast() == .tasks {
                        AppRouter.shared.removeLast()
                        if case .minecraftInstallOptions = AppRouter.shared.getLast() {
                            AppRouter.shared.removeLast()
                        }
                    }
                }
                
                TaskManager.shared.execute(task: task)
                AppRouter.shared.append(.tasks)
            }
        } catch {
            err("导入整合包失败：\(error)")
            hint("导入整合包失败：\(error.localizedDescription)", type: .critical)
        }
    }
}

private struct ImportButton: View {
    private let image: String
    private let label: String
    private let perform: () throws -> Void
    
    public init(_ image: String, _ label: String, perform: @escaping () throws -> Void) {
        self.image = image
        self.label = label
        self.perform = perform
    }
    
    var body: some View {
        MyListItem {
            HStack {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22)
                    .foregroundStyle(Color.color1)
                    .padding(.leading, 10)
                MyText(label)
                Spacer()
            }
            .padding(.vertical, 2)
        }
        .onTapGesture {
            try? perform()
        }
    }
}
