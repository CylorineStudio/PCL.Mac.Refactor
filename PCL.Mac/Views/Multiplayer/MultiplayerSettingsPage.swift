//
//  MultiplayerSettingsPage.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/2/1.
//

import SwiftUI

struct MultiplayerSettingsPage: View {
    @State private var customPeer: String = LauncherConfig.shared.multiplayerCustomPeer ?? ""
    
    var body: some View {
        CardContainer {
            MyCard("EasyTier 设置", foldable: false) {
                configLine(label: "自定义节点") {
                    MyTextField(text: $customPeer)
                        .onChange(of: customPeer) { newValue in
                            LauncherConfig.shared.multiplayerCustomPeer = newValue
                        }
                }
                
                HStack {
                    MyButton("删除 EasyTier", type: .red) {
                        EasyTierManager.shared.delete()
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
