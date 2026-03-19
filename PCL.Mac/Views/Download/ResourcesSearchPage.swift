//
//  ResourcesSearchPage.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/3/16.
//

import SwiftUI
import Core

struct ResourcesSearchPage: View {
    @StateObject private var viewModel: ResourcesSearchViewModel
    
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
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.searchResults) { project in
                            ProjectListItemView(project: project)
                                .onTapGesture {
                                    AppRouter.shared.append(.projectInstall(project: project))
                                }
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
            } catch is CancellationError {
            } catch {
                err("搜索\(viewModel.type.localizedName)失败：\(error.localizedDescription)")
                await MainActor.run {
                    viewModel.loadingVM.fail(with: "搜索\(viewModel.type.localizedName)失败：\(error.localizedDescription)")
                }
            }
        }
    }
}

struct ProjectListItemView: View {
    private let project: ProjectListItemModel
    
    init(project: ProjectListItemModel) {
        self.project = project
    }
    
    var body: some View {
        MyListItem {
            HStack {
                Group {
                    if let iconURL: URL = project.iconURL {
                        NetworkImage(url: iconURL)
                    } else {
                        Color.clear
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .frame(width: 48, height: 48)
                .padding(.leading, 4)
                
                VStack(alignment: .leading, spacing: 2) {
                    MyText(project.title, size: 16)
                        .lineLimit(1)
                    HStack {
                        ForEach(project.tags, id: \.self) { tag in
                            MyTag(tag, labelColor: .colorGray2, backgroundColor: .init(0x000000, alpha: 17 / 255), size: 12)
                        }
                        MyText(project.description, color: .colorGray3)
                            .lineLimit(1)
                    }
                    
                    HStack {
                        InformationView(icon: "SettingsPageIcon", text: project.supportDescription, width: 200)
                        InformationView(icon: "DownloadPageIcon", text: project.downloads, width: 150)
                        InformationView(icon: "IconUpload", text: project.lastUpdate, width: 150)
                        Spacer()
                    }
                    
                    Spacer(minLength: 0)
                }
                Spacer(minLength: 0)
            }
        }
    }
    
    private struct InformationView: View {
        private let icon: String
        private let text: String
        private let width: CGFloat
        
        init(icon: String, text: String, width: CGFloat) {
            self.icon = icon
            self.text = text
            self.width = width
        }
        
        var body: some View {
            HStack(spacing: 6) {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14)
                    .foregroundStyle(Color.colorGray3)
                MyText(text, size: 12, color: .colorGray3)
            }
            .frame(width: width, alignment: .leading)
        }
    }
}
