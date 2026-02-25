//
//  InstanceListSidebar.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/27.
//

import SwiftUI
import Core

struct InstanceListSidebar: Sidebar {
    @EnvironmentObject private var instanceViewModel: InstanceManager
    @EnvironmentObject private var viewModel: InstanceListViewModel
    
    let width: CGFloat = 300
    
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
                ImportButton("IconImportModpack", "导入整合包（暂未完成）") {
                    NSWorkspace.shared.open(URL(string: "https://www.bilibili.com/video/BV1GJ411x7h7")!)
                }
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
