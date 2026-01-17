//
//  AboutPage.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/7.
//

import SwiftUI
import Core

struct AboutPage: View {
    var body: some View {
        CardContainer {
            MyCard("关于", foldable: false) {
                VStack(spacing: 0) {
                    ProfileView("LTCatt", "龙腾猫跃", "Plain Craft Launcher 的作者！",
                                .init("GitHub", URL(string: "https://github.com/LTCatt")!),
                                .init("Afdian", URL(string: "https://afdian.com/a/LTCat")!))
                    
                    ProfileView("AnemoFlower", "风花AnemoFlower", "PCL.Mac 的作者",
                                .init("GitHub", URL(string: "https://github.com/AnemoFlower")!),
                                .init("Bilibili", URL(string: "https://space.bilibili.com/3461564927576750")!),
                                .init("Afdian", URL(string: "https://afdian.com/a/AnemoFlower")!))
                    
                    ProfileView("CeciliaStudio", "Cecilia Studio", "PCL.Mac 的开发团队",
                                .init("GitHub", URL(string: "https://github.com/CeciliaStudio")!),
                                .init("CeciliaStudio", URL(string: "https://ceciliastudio.top")!))
                    
                    ProfileView("PCL.Mac", "PCL.Mac.Refactor", "当前版本：\(Metadata.appVersion)",
                                .init("GitHub", URL(string: "https://github.com/CeciliaStudio/PCL.Mac.Refactor")!),
                                .init("CeciliaStudio", URL(string: "https://ceciliastudio.top/projects/PCL.Mac.Refactor")!))
                }
            }
            
            MyCard("特别鸣谢", foldable: false) {
                VStack(spacing: 0) {
                    ProfileView("PCL-Community", "PCL Community", "Plain Craft Launcher 非官方社区",
                                .init("GitHub", URL(string: "https://github.com/PCL-Community")!))
                    
                    ProfileView("PCL.Proto", "PCL.Proto", "以 PCL2 和 PCL2-CE 为蓝本，旨在为各 PCL 分支版本提供一个标准化的原型样本。",
                                .init("GitHub", URL(string: "https://github.com/PCL-Community/PCL.Proto")!))
                }
            }
        }
    }
    
    private struct ProfileView: View {
        private let image: String
        private let nickname: String
        private let description: String
        private let links: [Link]
        
        init(_ image: String, _ nickname: String, _ description: String, _ links: Link...) {
            self.image = image
            self.nickname = nickname
            self.description = description
            self.links = links
        }
        
        var body: some View {
            MyListItem {
                HStack {
                    Image(image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .clipShape(.circle)
                    VStack(alignment: .leading) {
                        MyText(nickname)
                        MyText(description, color: .colorGray3)
                    }
                    Spacer()
                    HStack {
                        ForEach(links, id: \.url) { link in
                            Image(link.image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 28, height: 28)
                                .clipShape(.circle)
                                .contentShape(.rect)
                                .onTapGesture {
                                    NSWorkspace.shared.open(link.url)
                                }
                        }
                    }
                    .padding(.trailing, 2)
                }
                .padding(2)
            }
        }
        
        struct Link {
            let image: String
            let url: URL
            
            init(_ image: String, _ url: URL) {
                self.image = image
                self.url = url
            }
        }
    }
}
