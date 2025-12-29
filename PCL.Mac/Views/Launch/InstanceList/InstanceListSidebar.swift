//
//  InstanceListSidebar.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/27.
//

import SwiftUI
import Core

struct InstanceListSidebar: Sidebar {
    @EnvironmentObject private var viewModel: InstanceListViewModel
    
    let width: CGFloat = 300
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !viewModel.repositories.isEmpty {
                MyText("目录列表", size: 12, color: .colorGray3)
                    .padding(.leading, 13)
                    .padding(.top, 18)
                MyNavigationList(
                    routeList: viewModel.repositories.map({ (AppRoute.instanceList($0), nil, $0.name) })
                ) { route in
                    if case .instanceList(let directory) = route {
                        do {
                            try directory.load()
                        } catch {
                            err("加载实例列表失败：\(error.localizedDescription)")
                            // TODO: Hint
                        }
                    }
                }
            }
            MyText("添加或导入", size: 12, color: .colorGray3)
                .padding(.leading, 13)
                .padding(.top, 18)
            VStack(spacing: 0) {
                ImportButton("IconAdd", "添加已有目录") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.allowedContentTypes = [.folder]
                    if panel.runModal() == .OK {
                        guard let url = panel.url else { return }
                        if viewModel.repositories.contains(where: { $0.url == url }) {
                            throw SimpleError("该目录已存在！")
                        }
                        viewModel.addRepository(url: url)
                    }
                }
                ImportButton("IconImportModpack", "导入整合包（暂未完成）") {
                    
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: viewModel.repositories) { newValue in
            if let repository = newValue.first, AppRouter.shared.getLast() == .emptyInstanceList {
                AppRouter.shared.removeLast()
                AppRouter.shared.append(.instanceList(repository))
            }
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
