//
//  InstalledModsPage.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/6/7.
//

import SwiftUI
import Core

struct InstalledModsPage: View {
    @StateObject private var viewModel: InstalledModsViewModel
    @StateObject private var loadingVM: MyLoadingViewModel
    
    init(instanceManager: InstanceManager, id: String) {
        self._viewModel = .init(wrappedValue: .init(instanceManager: instanceManager, id: id))
        self._loadingVM = .init(wrappedValue: MyLoadingViewModel(text: "加载中"))
    }
    
    var body: some View {
        CardContainer {
            if let mods = viewModel.mods {
                MyCard(nil) {
                    LazyVStack(spacing: 0) {
                        ForEach(mods, id: \.id) { mod in
                            ResourceListItem(resource: mod)
                        }
                    }
                }
            } else {
                MyLoading(viewModel: loadingVM)
            }
        }
        .task {
            do {
                try await viewModel.load()
            } catch {
                err("加载模组列表失败：\(error.localizedDescription)")
                loadingVM.fail(with: error.localizedDescription)
            }
        }
    }
}

private struct ResourceListItem: View {
    private let resource: ModDisplayModel
    
    init(resource: ModDisplayModel) {
        self.resource = resource
    }
    
    var body: some View {
        MyListItem {
            HStack {
                Group {
                    switch resource.icon {
                    case .resource(let imageResource): Image(imageResource).resizable()
                    case .nsImage(let nsImage): Image(nsImage: nsImage).resizable()
                            .interpolation(.none)
                    case .network(let url): NetworkImage(url: url)
                    }
                }
                .scaledToFit()
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .foregroundStyle(Color.color1)
                
                VStack(alignment: .leading) {
                    MyText(resource.name)
                        .lineLimit(1)
                    MyText("\(resource.version) | \(resource.description)", color: .colorGray3)
                        .lineLimit(1)
                }
                
                Spacer()
            }
        }
    }
}
