//
//  HomepageView.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/6/2.
//

import SwiftUI
import Core

struct HomepageView: View {
    @StateObject private var viewModel: HomepageViewModel = .init()
    
    var body: some View {
        CardContainer {
            if let homepage = viewModel.homepage {
                ForEach(Array(homepage.components.enumerated()), id: \.offset) { _, component in
                    AnyView(component.makeView())
                }
            } else {
                MyTip(text: "正在加载主页……", theme: .blue)
            }
        }
        .task {
            do {
                try await viewModel.load(from: .local(URLConstants.resourcesURL.appending(path: "debug.xml")))
            } catch {   
                err("加载主页失败：\(error.localizedDescription)")
                hint("加载主页失败：\(error.localizedDescription)", type: .critical)
            }
        }
    }
}
