//
//  MultiplayerSettingsPage.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/2/1.
//

import SwiftUI

struct MultiplayerSettingsPage: View {
    var body: some View {
        CardContainer {
            MyCard("EasyTier 设置", foldable: false) {
                HStack {
                    MyButton("删除 EasyTier", type: .red) {
                        EasyTierManager.shared.delete()
                    }
                    .frame(width: 130)
                    Spacer()
                }
                .frame(height: 32)
            }
        }
    }
}
