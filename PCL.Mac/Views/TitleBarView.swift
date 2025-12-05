//
//  TitleBarView.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/10.
//

import SwiftUI

struct TitleBarView: View {
    var body: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(.blue)
            HStack {
                Image("Title")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.white)
                    .frame(height: 19)
                    .padding(.leading, 65)
                Badge("Mac")
                Badge("Dev", labelColor: Color(0x343D4A), backgroundColor: Color(0x9BF00B))
            }
            HStack {
                Spacer()
                PageButton("启动", "LaunchPageIcon", .launch)
                PageButton("下载", "DownloadPageIcon", .download)
                PageButton("联机", "MultiplayerPageIcon", .multiplayer)
                PageButton("设置", "SettingsPageIcon", .settings)
                PageButton("更多", "OthersPageIcon", .other)
                Spacer()
            }
        }
        .frame(height: 48)
    }
    
    struct Badge: View {
        private let label: String
        private let labelColor: Color
        private let backgroundColor: Color
        
        init(_ label: String, labelColor: Color = .pclBlue, backgroundColor: Color = .white) {
            self.label = label
            self.labelColor = labelColor
            self.backgroundColor = backgroundColor
        }
        
        var body: some View {
            MyText(label, color: labelColor)
                .padding(2)
                .background {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(backgroundColor)
                }
        }
    }
}

private struct PageButton: View {
    @ObservedObject private var router: AppRouter = .shared
    @State private var hovered: Bool = false
    private var isRoot: Bool { router.getRoot() == route }
    private let label: String
    private let image: String
    private let route: AppRoute
    
    init(_ label: String, _ image: String, _ route: AppRoute) {
        self.label = label
        self.image = image
        self.route = route
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 13)
                .fill(backgroundColor)
            HStack(spacing: 7) {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16)
                    .foregroundStyle(foregroundColor)
                MyText(label, color: foregroundColor)
            }
        }
        .frame(width: 78, height: 27)
        .contentShape(Rectangle())
        .onHover { hovered in
            self.hovered = hovered
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if router.getRoot() != route {
                        router.setRoot(route)
                    }
                }
        )
        .animation(.easeInOut(duration: 0.2), value: isRoot)
        .animation(.easeInOut(duration: 0.2), value: hovered)
    }
    
    private var foregroundColor: Color {
        isRoot ? .pclBlue : .white
    }
    
    private var backgroundColor: Color {
        isRoot ? .white : (hovered ? .init(0xFFFFFF, alpha: 0.25) : .clear)
    }
}
