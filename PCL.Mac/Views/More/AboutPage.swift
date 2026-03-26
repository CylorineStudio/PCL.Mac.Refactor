//
//  AboutPage.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/1/7.
//

import SwiftUI
import Core

struct AboutPage: View {
    var body: some View {
        CardContainer {
            MyCard("关于", foldable: false) {
                VStack(spacing: 0) {
                    ProfileView("LTCatt", "龙腾猫跃", "Plain Craft Launcher 的作者！",
                                .init("GitHub 主页", "https://github.com/LTCatt"),
                                .init("前往赞助", "https://afdian.com/a/LTCat"))
                    
                    ProfileView("AnemoFlower", "风花AnemoFlower", "PCL.Mac 的作者",
                                .init("GitHub 主页", "https://github.com/AnemoFlower"),
                                .init("Bilibili 主页", "https://space.bilibili.com/3461564927576750"),
                                .init("前往赞助", "https://afdian.com/a/AnemoFlower"))
                    
                    ProfileView("https://cylorine.studio/img/cylorine-studio.png", "Cylorine Studio", "PCL.Mac 的开发团队",
                                .init("GitHub 主页", "https://github.com/CylorineStudio"),
                                .init("官方网站", "https://cylorine.studio"))
                    
                    ProfileView("PCL.Mac", "PCL.Mac.Refactor", "当前版本：\(Metadata.appVersion) (\(Metadata.bundleVersion))",
                                .init("GitHub 仓库", "https://github.com/CylorineStudio/PCL.Mac.Refactor"),
                                .init("官网页面", "https://cylorine.studio/projects/PCL.Mac.Refactor"))
                }
            }
            
            MyCard("特别鸣谢", foldable: false) {
                VStack(spacing: 0) {
                    ProfileView("PCL-Community", "PCL Community", "Plain Craft Launcher 非官方社区",
                                .init("GitHub 主页", "https://github.com/PCL-Community"))
                    
                    ProfileView("PCL.Proto", "PCL.Proto", "以 PCL2 和 PCL2-CE 为蓝本，旨在为各 PCL 分支版本提供一个标准化的原型样本。",
                                .init("GitHub 仓库", "https://github.com/PCL-Community/PCL.Proto"))
                    
                    ProfileView("bangbang93", "bangbang93", "提供 BMCLAPI 镜像源，详见 https://bmclapi.bangbang93.com",
                                .init("前往赞助", "https://afdian.com/a/bangbang93"))
                }
            }
        }
    }
    
    private struct ProfileView: View {
        @ObservedObject private var easterEggManager: EasterEggManager = .shared
        @Environment(\.disableHoverAnimation) private var cardAppearAnimationPlaying: Bool
        
        private let image: String
        private let imageURL: URL?
        private let nickname: String
        private let description: String
        private let links: [Link]
        
        init(_ image: String, _ nickname: String, _ description: String, _ links: Link...) {
            self.image = image
            if let url: URL = .init(string: image), url.scheme == "https" {
                self.imageURL = url
            } else {
                self.imageURL = nil
            }
            self.nickname = nickname
            self.description = description
            self.links = links
        }
        
        var body: some View {
            MyListItem {
                HStack {
                    Group {
                        if let imageURL {
                            NetworkImage(url: imageURL)
                        } else {
                            Image(image)
                                .resizable()
                        }
                    }
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .clipShape(.circle)
                    .contrast(easterEggManager.modifyColor ? -1 : 1) // 防止“千万别点”颜色反转影响到头像
                    VStack(alignment: .leading) {
                        MyText(nickname)
                        MyText(description, color: .colorGray3)
                    }
                    Spacer()
                    HStack {
                        ForEach(links, id: \.url) { link in
                            MyButton(link.buttonName) {
                                if let url: URL = .init(string: link.url) {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                            .frame(width: 100)
                        }
                    }
                    .padding(.trailing, 2)
                }
                .padding(2)
            }
        }
        
        struct Link {
            let buttonName: String
            let url: String
            
            init(_ buttonName: String, _ url: String) {
                self.buttonName = buttonName
                self.url = url
            }
        }
    }
}
