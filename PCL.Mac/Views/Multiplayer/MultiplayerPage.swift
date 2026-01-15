//
//  MultiplayerPage.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/15.
//

import SwiftUI

struct MultiplayerPage: View {
    var body: some View {
        CardContainer {
            MyCard("开始联机", foldable: false) {
                VStack(spacing: 0) {
                    MultiplayerListItem("MultiplayerPageIcon", "创建房间", "创建房间并生成邀请码，与好友一起畅玩")
                    MultiplayerListItem("IconAdd", "加入房间", "输入房主提供的邀请码，加入游戏世界")
                }
            }
        }
    }
}

private struct MultiplayerListItem: View {
    private let icon: String
    private let text: String
    private let description: String
    
    init(_ icon: String, _ text: String, _ description: String) {
        self.icon = icon
        self.text = text
        self.description = description
    }
    
    var body: some View {
        MyListItem {
            HStack {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundStyle(Color.color1)
                VStack(alignment: .leading) {
                    MyText(text)
                    MyText(description, color: .colorGray3)
                }
                Spacer(minLength: 0)
            }
            .frame(height: 36)
        }
    }
}
