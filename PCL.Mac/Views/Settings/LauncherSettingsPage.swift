//
//  LauncherSettingsPage.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/7/9.
//

import SwiftUI
import Core

struct LauncherSettingsPage: View {
    @State private var downloadSourcePolicy: DownloadSourcePolicy = LauncherConfig.shared.downloadSourcePolicy
    
    var body: some View {
        CardContainer {
            MyCard("下载", foldable: false) {
                configLine(label: "下载源") {
                    MySelect(
                        $downloadSourcePolicy,
                        entries: [.officialFirst, .mirrorFirst]
                    )
                }
                .onChange(of: downloadSourcePolicy) { newValue in
                    DownloadSourceManager.shared.policy = newValue
                    LauncherConfig.shared.downloadSourcePolicy = newValue
                }
            }
        }
    }
    
    @ViewBuilder
    private func configLine(label: String,  @ViewBuilder body: () -> some View) -> some View {
        HStack(spacing: 20) {
            MyText(label)
                .frame(width: 80, alignment: .leading)
            HStack {
                Spacer(minLength: 0)
                body()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 6)
    }
}
