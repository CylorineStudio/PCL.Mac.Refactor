//
//  AboutPage.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/7.
//

import SwiftUI

struct AboutPage: View {
    var body: some View {
        CardContainer {
            MyCard("关于", foldable: false) {
                VStack(spacing: 0) {
                    ProfileView("LTCatt", "龙腾猫跃", "Plain Craft Launcher 的作者！")
                    ProfileView("AnemoFlower", "风花AnemoFlower", "PCL.Mac 的作者")
                    ProfileView("CeciliaStudio", "Cecilia Studio", "PCL.Mac 的开发团队")
                    ProfileView("PCL.Mac", "Cecilia Studio", "PCL.Mac 的开发团队")
                }
            }
        }
    }
    
    private struct ProfileView: View {
        private let image: String
        private let nickname: String
        private let description: String
        
        init(_ image: String, _ nickname: String, _ description: String) {
            self.image = image
            self.nickname = nickname
            self.description = description
        }
        
        var body: some View {
            MyListItem {
                HStack {
                    Image(image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                    VStack(alignment: .leading) {
                        MyText(nickname)
                        MyText(description, color: .colorGray3)
                    }
                    Spacer()
                }
                .padding(2)
            }
        }
    }
}
