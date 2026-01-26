//
//  PlayerAvatar.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/18.
//

import SwiftUI
import Core

struct PlayerAvatar: View {
    @StateObject private var viewModel: AccountViewModel = .init()
    @State private var skinImage: CIImage?
    private let account: Account
    private let length: CGFloat
    
    init(_ account: Account, length: CGFloat = 58) {
        self.account = account
        self.length = length
    }
    
    var body: some View {
        ZStack {
            if let skinImage {
                SkinLayerView(image: skinImage, startX: 8, startY: 16)
                    .frame(width: length / 10 * 9)
                SkinLayerView(image: skinImage, startX: 40, startY: 16)
                    .frame(width: length)
            }
        }
        .shadow(radius: 2)
        .frame(width: length, height: length)
        .task {
            let skinData: Data = await viewModel.skinData(for: account)
            guard let image: CIImage = .init(data: skinData) else {
                err("加载 CIImage 失败")
                return
            }
            await MainActor.run {
                self.skinImage = image
            }
        }
    }
}

private struct SkinLayerView: View {
    private let image: NSImage?
    
    init(image: CIImage, startX: CGFloat, startY: CGFloat) {
        let yOffset: CGFloat = image.extent.height == 32 ? 0 : 32
        let cropped: CIImage = image.cropped(to: CGRect(x: startX, y: startY + yOffset, width: 8, height: 8))
        let context: CIContext = .init()
        guard let cgImage = context.createCGImage(cropped, from: cropped.extent) else {
            warn("创建 CGImage 失败")
            self.image = nil
            return
        }
        self.image = NSImage(cgImage: cgImage, size: cropped.extent.size)
    }
    
    var body: some View {
        if let image {
            Image(nsImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
        }
    }
}
