//
//  MyLoading.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/7.
//

import SwiftUI

struct MyLoading: View {
    @ObservedObject private var viewModel: MyLoadingViewModel
    /// 是否显示为失败，只会在下一次敲击开始前被修改
    @State private var isFailed: Bool = false
    
    @State private var pickaxeAngle: Double = 0
    @State private var leftPathOffset: CGSize = .zero
    @State private var rightPathOffset: CGSize = .zero
    @State private var pathOpacity: CGFloat = 1
    @State private var timer = Timer.publish(every: 1.68, on: .main, in: .common).autoconnect()
    
    private let showCard: Bool
    
    init(viewModel: MyLoadingViewModel, showCard: Bool = true) {
        self.viewModel = viewModel
        self.showCard = showCard
    }
    
    var body: some View {
        Group {
            if showCard {
                MyCard("", titled: false) {
                    pickaxe
                }
            } else {
                pickaxe
            }
        }
        .fixedSize()
        .onReceive(timer) { _ in
            animate()
        }
        .onAppear(perform: animate)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isFailed)
        .onChange(of: viewModel.isFailed) { newValue in
            if newValue == false {
                isFailed = false
                animate()
            }
        }
    }
    
    private var pickaxe: some View {
        VStack {
            ZStack {
                // 横线
                Path { path in
                    path.move(to: CGPoint(x: 5, y: 66))
                    path.addLine(to: CGPoint(x: 29, y: 66))
                }
                .stroke(viewModel.isFailed ? Color.red : Color.color2, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                
                // 镐子
                Path { path in
                    path.move(to: CGPoint(x: 53.7693, y: 59.6884))
                    path.addLine(to: CGPoint(x: 53.7763, y: 27.5221))
                    path.addCurve(to: CGPoint(x: 67.6568, y: 31.1071), control1: CGPoint(x: 59.2904, y: 27.6694), control2: CGPoint(x: 62.7075, y: 30.1275))
                    path.addCurve(to: CGPoint(x: 71.1429, y: 29.9828), control1: CGPoint(x: 73.6227, y: 32.4731), control2: CGPoint(x: 74.8377, y: 33.7263))
                    path.addCurve(to: CGPoint(x: 55.6855, y: 22.2612), control1: CGPoint(x: 66.9914, y: 25.9769), control2: CGPoint(x: 61.6417, y: 23.1999))
                    path.addCurve(to: CGPoint(x: 51.1671, y: 18.7045), control1: CGPoint(x: 55.1971, y: 20.2186), control2: CGPoint(x: 53.3582, y: 18.7011))
                    path.addCurve(to: CGPoint(x: 46.6487, y: 22.2612), control1: CGPoint(x: 48.976, y: 18.7078), control2: CGPoint(x: 47.138, y: 20.2185))
                    path.addCurve(to: CGPoint(x: 31.1913, y: 29.9828), control1: CGPoint(x: 40.6892, y: 23.2052), control2: CGPoint(x: 35.3415, y: 25.9781))
                    path.addCurve(to: CGPoint(x: 34.6703, y: 31.1142), control1: CGPoint(x: 26.8344, y: 34.236), control2: CGPoint(x: 28.2414, y: 32.9395))
                    path.addCurve(to: CGPoint(x: 48.5579, y: 27.5221), control1: CGPoint(x: 39.6201, y: 30.1326), control2: CGPoint(x: 43.0467, y: 27.6687))
                    path.addLine(to: CGPoint(x: 48.5508, y: 59.6884))
                    path.addLine(to: CGPoint(x: 53.7056, y: 59.752))
                    path.addLine(to: CGPoint(x: 53.7693, y: 59.6884))
                    path.closeSubpath()
                }
                .stroke(viewModel.isFailed ? Color.red : Color.color2, lineWidth: 2)
                .rotationEffect(.init(degrees: pickaxeAngle), anchor: .init(x: 0.625, y: 0.6875))
                
                // 小碎片
                Group {
                    Path { path in
                        path.move(to: CGPoint(x: 11, y: 61.67))
                        path.addLine(to: CGPoint(x: 12.8992, y: 60.0019))
                        path.addLine(to: CGPoint(x: 15.2859, y: 64.6345))
                    }
                    .offset(leftPathOffset)
                    
                    Path { path in
                        path.move(to: CGPoint(x: 19.7416, y: 60.147))
                        path.addLine(to: CGPoint(x: 21.4566, y: 62.0039))
                        path.addLine(to: CGPoint(x: 16.8852, y: 64.5056))
                    }
                    .offset(rightPathOffset)
                }
                .opacity(pathOpacity)
                
                // 叉叉
                if isFailed {
                    Group {
                        Path { path in
                            path.move(to: CGPoint(x: 10.2929, y: 49.2929))
                            path.addCurve(to: CGPoint(x: 20.2929, y: 60.7071), control1: CGPoint(x: 9.90237, y: 49.6834), control2: CGPoint(x: 9.90237, y: 50.3166))
                            path.addCurve(to: CGPoint(x: 21.7071, y: 60.7071), control1: CGPoint(x: 20.6834, y: 61.0976), control2: CGPoint(x: 21.3166, y: 61.0976))
                            path.addCurve(to: CGPoint(x: 21.7071, y: 59.2929), control1: CGPoint(x: 22.0976, y: 60.3166), control2: CGPoint(x: 22.0976, y: 59.6834))
                            path.addCurve(to: CGPoint(x: 11.7071, y: 49.2929), control1: CGPoint(x: 21.7071, y: 59.2929), control2: CGPoint(x: 11.7071, y: 49.2929))
                            path.addCurve(to: CGPoint(x: 10.2929, y: 49.2929), control1: CGPoint(x: 11.3166, y: 48.9024), control2: CGPoint(x: 10.6834, y: 48.9024))
                            path.closeSubpath()
                        }
                        
                        Path { path in
                            path.move(to: CGPoint(x: 10.2929, y: 60.7071))
                            path.addCurve(to: CGPoint(x: 11.7071, y: 60.7071), control1: CGPoint(x: 10.6834, y: 61.0976), control2: CGPoint(x: 11.3166, y: 61.0976))
                            path.addCurve(to: CGPoint(x: 21.7071, y: 50.7071), control1: CGPoint(x: 22.0977, y: 50.3166), control2: CGPoint(x: 22.0976, y: 49.6835))
                            path.addCurve(to: CGPoint(x: 21.7071, y: 49.2929), control1: CGPoint(x: 21.7071, y: 49.6835), control2: CGPoint(x: 21.3166, y: 48.9024))
                            path.addCurve(to: CGPoint(x: 20.2929, y: 49.2929), control1: CGPoint(x: 20.6834, y: 48.9024), control2: CGPoint(x: 20.2929, y: 49.2929))
                            path.addCurve(to: CGPoint(x: 10.2929, y: 59.2929), control1: CGPoint(x: 20.2929, y: 49.2929), control2: CGPoint(x: 10.2929, y: 59.2929))
                            path.addCurve(to: CGPoint(x: 10.2929, y: 60.7071), control1: CGPoint(x: 9.9024, y: 59.6834), control2: CGPoint(x: 9.9024, y: 60.3166))
                            path.closeSubpath()
                        }
                    }
                }
            }
            .foregroundStyle(viewModel.isFailed ? Color.red : Color.color2)
            .frame(width: 80, height: 80)
            MyText(viewModel.text, size: 16, color: viewModel.isFailed ? Color.red : Color.color2)
        }
    }
    
    private func animate() {
        if isFailed { return }
        Task {
            try await setPickaxeAngle(-65, duration: 0.35, animation: .easeIn(duration: 0.35), wait: true)
            await MainActor.run {
                leftPathOffset = .zero
                rightPathOffset = .zero
                pathOpacity = 1
                withAnimation(.easeOut(duration: 0.18)) {
                    leftPathOffset = .init(width: -5, height: -6)
                    rightPathOffset = .init(width: 5, height: -6)
                    pathOpacity = 0
                }
            }
            try await setPickaxeAngle(50, duration: 0.35, animation: .easeOut(duration: 0.35), wait: true)
            try await setPickaxeAngle(25, duration: 0.35, animation: .easeOut(duration: 0.35))
            if viewModel.isFailed {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        self.isFailed = true
                    }
                }
            }
        }
    }
    
    private func setPickaxeAngle(_ value: Double, duration: Double, animation: Animation, wait: Bool = false) async throws {
        await MainActor.run {
            withAnimation(animation) {
                self.pickaxeAngle = value
            }
        }
        if wait {
            try await Task.sleep(seconds: duration)
        }
    }
}

fileprivate struct PreviewView: View {
    private let viewModel: MyLoadingViewModel = .init(text: "加载中")
    
    var body: some View {
        VStack {
            MyLoading(viewModel: viewModel)
            MyButton("fail()") { viewModel.fail(with: "网络环境不佳，请重试或尝试使用 VPN") }
        }
        .padding()
    }
}

#Preview {
    PreviewView()
}
