//
//  InstanceConfigPage.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/2/2.
//

import SwiftUI
import Core

struct InstanceConfigPage: View {
    @EnvironmentObject private var instanceVM: InstanceManager
    @StateObject private var viewModel: InstanceConfigViewModel
    @StateObject private var loadingVM: MyLoadingViewModel = .init(text: "加载中")
    
    init(id: String) {
        self._viewModel = .init(wrappedValue: .init(id: id))
    }
    
    var body: some View {
        CardContainer {
            if viewModel.loaded {
                MyCard("", titled: false, padding: 10) {
                    MyListItem(.init(image: viewModel.iconName, name: viewModel.id, description: viewModel.description))
                }
                jvmCard
            } else {
                MyLoading(viewModel: loadingVM)
            }
        }
        .task(id: viewModel.id) {
            do {
                try await viewModel.load()
            } catch {
                await MainActor.run {
                    loadingVM.fail(with: "加载失败：\(error.localizedDescription)")
                }
            }
        }
        .task {
            try? await Task.sleep(seconds: 5)
            debug(viewModel.loaded)
        }
    }
    
    @ViewBuilder
    private var jvmCard: some View {
        MyCard("JVM 设置", foldable: false) {
            VStack {
                configLine(label: "使用的 Java") {
                    MyText(viewModel.javaDescription)
                }
                configLine(label: "内存分配") {
                    MyTextField(text: $viewModel.jvmHeapSize)
                        .onChange(of: viewModel.jvmHeapSize) { newValue in
                            if let jvmHeapSize: UInt64 = .init(newValue) { viewModel.setHeapSize(jvmHeapSize) }
                        }
                    MyText("MB")
                }
                HStack(spacing: 30) {
                    MyButton("切换 Java") {
                        let runtimes: [JavaRuntime] = viewModel.javaList()
                        Task {
                            if let index: Int = await MessageBoxManager.shared.showList(
                                title: "切换 Java",
                                items: runtimes.map { .init(name: $0.description, description: $0.executableURL.path) }
                            ) {
                                let runtime: JavaRuntime = runtimes[index]
                                do {
                                    try viewModel.switchJava(to: runtime)
                                } catch let error as InstanceConfigViewModel.Error {
                                    switch error {
                                    case .invalidJavaVersion(let min):
                                        _ = await MessageBoxManager.shared.showText(
                                            title: "Java 版本不满足要求",
                                            content: "这个实例需要 Java \(min) 才能启动，但你选择的是 Java \(runtime.version)！",
                                            level: .error
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .frame(minWidth: 150)
                    .fixedSize(horizontal: true, vertical: false)
                    Spacer()
                }
                .frame(height: 35)
                .padding(.top, 12)
            }
        }
    }
    
    @ViewBuilder
    private func configLine(label: String,  @ViewBuilder body: () -> some View) -> some View {
        HStack(spacing: 20) {
            MyText(label)
                .frame(width: 120, alignment: .leading)
            HStack {
                Spacer(minLength: 0)
                body()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 6)
    }
}
