//
//  JavaSettingsPage.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/3/6.
//

import SwiftUI
import Core

struct JavaSettingsPage: View {
    @StateObject private var viewModel: JavaSettingsViewModel = .init()
    
    var body: some View {
        CardContainer {
            MyCard("", titled: false) {
                HStack {
                    MyButton("刷新 Java 列表") {
                        do {
                            try JavaManager.shared.research()
                            hint("刷新成功！", type: .finish)
                        } catch {
                            err("刷新 Java 列表失败：\(error.localizedDescription)")
                            hint("刷新 Java 列表失败：\(error.localizedDescription)", type: .critical)
                        }
                    }
                    .frame(width: 120)
                    
                    MyButton("安装 Java") {
                        Task {
                            do {
                                let downloads: [MojangJavaList.JavaDownload] = try await viewModel.javaDownloads()
                                if let index: Int = await MessageBoxManager.shared.showListAsync(
                                    title: "选择 Java 版本",
                                    items: downloads.map(viewModel.listItem(forJavaDownload:))
                                ) {
                                    TaskManager.shared.execute(task: JavaInstallTask.create(download: downloads[index]))
                                    AppRouter.shared.append(.tasks)
                                }
                            } catch {
                                err("拉取 Java 列表失败：\(error.localizedDescription)")
                                hint("拉取 Java 列表失败：\(error.localizedDescription)", type: .critical)
                            }
                        }
                    }
                    .frame(width: 120)
                    Spacer()
                }
                .frame(height: 40)
            }
            
            MyCard("Java 列表", folded: false) {
                MyList(items: viewModel.javaList)
            }
            .cardIndex(1)
        }
    }
}
