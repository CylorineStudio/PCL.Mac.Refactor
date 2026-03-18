//
//  ResourcesDownloadPage.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/3/16.
//

import SwiftUI
import Core

struct ResourcesDownloadPage: View {
    @StateObject private var viewModel: ResourcesViewModel
    
    init(type: ModrinthProjectType) {
        self._viewModel = StateObject(wrappedValue: .init(type: type))
    }
    
    var body: some View {
        CardContainer {
            MySearchBox(placeholder: "搜索\(viewModel.type.localizedName)") { query in
                Task {
                    do {
                        viewModel.loadingVM.reset()
                        try await viewModel.search(query)
                    } catch {
                        err("搜索\(viewModel.type.localizedName)失败：\(error.localizedDescription)")
                        await MainActor.run {
                            viewModel.loadingVM.fail(with: "搜索\(viewModel.type.localizedName)失败：\(error.localizedDescription)")
                        }
                    }
                }
            }
            
            if !viewModel.searchResults.isEmpty {
                MyCard("", titled: false) {
                    VStack(spacing: 0) {
                        ForEach(viewModel.searchResults) { model in
                            ProjectListItem(model: model)
                        }
                    }
                }
            } else {
                MyLoading(viewModel: viewModel.loadingVM)
            }
        }
        .task {
            do {
                try await viewModel.search("")
            } catch {
                err("搜索\(viewModel.type.localizedName)失败：\(error.localizedDescription)")
                await MainActor.run {
                    viewModel.loadingVM.fail(with: "搜索\(viewModel.type.localizedName)失败：\(error.localizedDescription)")
                }
            }
        }
    }
}

private struct ProjectListItem: View {
    private let model: ProjectListItemModel
    
    init(model: ProjectListItemModel) {
        self.model = model
    }
    
    var body: some View {
        MyListItem {
            HStack {
                Group {
                    if let iconURL: URL = model.iconURL {
                        AsyncImage(url: iconURL) { phase in
                            if case .success(let image) = phase {
                                image
                                    .resizable()
                                    .scaledToFit()
                            } else {
                                Color.clear
                            }
                        }
                    } else {
                        Color.clear
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .frame(width: 48, height: 48)
                .padding(.leading, 6)
                
                VStack(alignment: .leading) {
                    MyText(model.title, size: 16)
                        .lineLimit(1)
                    HStack {
                        ForEach(model.tags, id: \.self) { tag in
                            MyTag(tag, backgroundColor: .init(0x000000, alpha: 17 / 255), size: 12)
                        }
                        MyText(model.description, color: .colorGray3)
                            .lineLimit(1)
                    }
                    .padding(.top, -6)
                    MyText("111")
                    Spacer(minLength: 0)
                }
                Spacer(minLength: 0)
            }
        }
    }
}
