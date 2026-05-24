//
//  MultiplayerSettingsPage.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/2/1.
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
                    .frame(minWidth: 150)
                    .fixedSize(horizontal: true, vertical: false)
                    Spacer()
                }
                .frame(height: 35)
            }
        }
    }
}
