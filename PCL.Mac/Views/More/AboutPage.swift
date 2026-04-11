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
                    ProfileView(.local(.ltCatt), "龙腾猫跃", "Plain Craft Launcher 的作者！",
                                .init("GitHub 主页", "https://github.com/LTCatt"),
                                .init("前往赞助", "https://afdian.com/a/LTCat"))
                    
                    ProfileView(.network(url: "https://cylorine.studio/img/avatar/AnemoFlower.png"), "风花AnemoFlower", "PCL.Mac 的作者",
                                .init("GitHub 主页", "https://github.com/AnemoFlower"),
                                .init("Bilibili 主页", "https://space.bilibili.com/3461564927576750"),
                                .init("前往赞助", "https://afdian.com/a/AnemoFlower"))
                    
                    ProfileView(.network(url: "https://cylorine.studio/img/avatar/CylorineStudio.png"), "Cylorine Studio", "PCL.Mac 的开发团队",
                                .init("GitHub 主页", "https://github.com/CylorineStudio"),
                                .init("官方网站", "https://cylorine.studio"))
                    
                    ProfileView(.local(.pclMac), "PCL.Mac.Refactor", "当前版本：\(Metadata.appVersion) (\(Metadata.bundleVersion))",
                                .init("GitHub 仓库", "https://github.com/CylorineStudio/PCL.Mac.Refactor"),
                                .init("官网页面", "https://cylorine.studio/projects/PCL.Mac.Refactor"))
                }
            }
            
            MyCard("特别鸣谢", foldable: false) {
                VStack(spacing: 0) {
                    ProfileView(.local(.pclCommunity), "PCL Community", "Plain Craft Launcher 非官方社区",
                                .init("GitHub 主页", "https://github.com/PCL-Community"))
                    
                    ProfileView(.local(.pclProto), "PCL.Proto", "以 PCL2 和 PCL2-CE 为蓝本，旨在为各 PCL 分支版本提供一个标准化的原型样本。",
                                .init("GitHub 仓库", "https://github.com/PCL-Community/PCL.Proto"))
                    
                    ProfileView(.local(.bangbang93), "bangbang93", "提供 BMCLAPI 镜像源，详见 https://bmclapi.bangbang93.com",
                                .init("前往赞助", "https://afdian.com/a/bangbang93"))
                }
            }
            
            MyCard("许可与版权声明", foldable: false) {
                VStack(spacing: 0) {
                    LicenseListItem("SwiftyJSON", license: "MIT", github: "SwiftyJSON/SwiftyJSON")
                    LicenseListItem("ZIPFoundation", license: "MIT", github: "weichsel/ZIPFoundation")
                    LicenseListItem("SwiftScaffolding", license: "MIT", github: "CylorineStudio/SwiftScaffolding")
                    LicenseListItem("EasyTier", license: "LGPL-3.0", github: "EasyTier/EasyTier")
                }
            }
        }
    }
    
    private struct ProfileView: View {
        @ObservedObject private var easterEggManager: EasterEggManager = .shared
        @Environment(\.disableHoverAnimation) private var cardAppearAnimationPlaying: Bool
        
        private let avatar: Avatar
        private let avatarURL: URL?
        private let nickname: String
        private let description: String
        private let links: [Link]
        
        init(_ avatar: Avatar, _ nickname: String, _ description: String, _ links: Link...) {
            self.avatar = avatar
            if case .network(let url) = avatar {
                self.avatarURL = URL(string: url)
            } else {
                self.avatarURL = nil
            }
            self.nickname = nickname
            self.description = description
            self.links = links
        }
        
        var body: some View {
            MyListItem {
                HStack {
                    Group {
                        switch avatar {
                        case .local(let imageResource): Image(imageResource).resizable()
                        case .network(_):
                            if let avatarURL {
                                NetworkImage(url: avatarURL)
                            } else {
                                Image(nsImage: .init())
                            }
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
        
        enum Avatar {
            case local(ImageResource)
            case network(url: String)
        }
    }
    
    private struct LicenseListItem: View {
        private let name: String
        private let license: String
        private let github: String
        
        init(_ name: String, license: String, github: String) {
            self.name = name
            self.license = license
            self.github = github
        }
        
        var body: some View {
            MyListItem(.init(name: name, description: "\(license) license | https://github.com/\(github)"))
        }
    }
}
