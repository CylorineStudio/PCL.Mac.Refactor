//
//  InstanceConfigPage.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/2/2.
//

import SwiftUI
import Core

struct InstanceConfigPage: View {
    @EnvironmentObject private var instanceVM: InstanceViewModel
    @StateObject private var loadingVM: MyLoadingViewModel = .init(text: "加载中")
    @State private var instance: MinecraftInstance?
    private let id: String
    
    init(id: String) {
        self.id = id
    }
    
    var body: some View {
        CardContainer {
            if let instance {
                MyCard("", titled: false, padding: 10) {
                    MyListItem(.init(image: "GrassBlock", name: instance.name, description: instance.version.id))
                }
                jvmCard(instance)
            } else {
                MyLoading(viewModel: loadingVM)
            }
        }
        .task(id: id) {
            do {
                let instance: MinecraftInstance = try instanceVM.loadInstance(id)
                await MainActor.run {
                    self.instance = instance
                }
            } catch {
                await MainActor.run {
                    loadingVM.fail(with: "加载失败：\(error.localizedDescription)")
                }
            }
        }
    }
    
    @ViewBuilder
    private func jvmCard(_ instance: MinecraftInstance) -> some View {
        MyCard("JVM 设置", foldable: false) {
            VStack {
                configLine(label: "内存分配") {
                    MyTextField(initial: instance.config.jvmHeapSize, parse: { .init($0) }) { value in
                        instance.setJVMHeapSize(value)
                    }
                    MyText("MB")
                }
            }
        }
    }
    
    @ViewBuilder
    private func configLine(label: String,  @ViewBuilder body: () -> some View) -> some View {
        HStack(spacing: 20) {
            MyText(label)
                .frame(width: 120, alignment: .leading)
            HStack {
                body()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 6)
    }
}
