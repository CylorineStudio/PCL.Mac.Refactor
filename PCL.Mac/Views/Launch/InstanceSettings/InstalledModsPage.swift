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
        Group {
            if !viewModel.supportMods {
                MyCard(nil) {
                    VStack(spacing: 10) {
                        MyText("该实例不可使用 Mod", size: 19, color: .color3)
                        
                        Rectangle()
                            .fill(Color.color3)
                            .frame(height: 2)
                        
                        MyText("你需要先安装 Forge、Fabric 等 Mod 加载器才能使用 Mod，请在安装实例时选择这些加载器。\n如果你已经安装了 Mod 加载器，那么你很可能选择了错误的实例，请点击实例选择按钮切换实例。")
                            .padding(.vertical, 5)
                        
                        HStack(spacing: 20) {
                            MyButton("转到下载页面", type: .highlight) {
                                AppRouter.shared.setRoot(.download)
                            }
                            .frame(width: 140)
                            MyButton("实例选择") {
                                AppRouter.shared.setRoot(.launch)
                                AppRouter.shared.append(.instanceList(repositoryId: viewModel.currentRepositoryId))
                            }
                            .frame(width: 140)
                        }
                        .frame(height: 35)
                    }
                    .padding(10)
                }
                .padding(40)
            } else {
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
            }
        }
        .task {
            do {
                try await viewModel.load()
            } catch {
                err("加载模组列表失败：\(error.localizedDescription)")
                loadingVM.fail(with: "加载模组列表失败：\(error.localizedDescription)")
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
                    case .nsImage(let nsImage): Image(nsImage: nsImage).resizable().interpolation(.none)
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
