//
//  RootView.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/4/16.
//

import SwiftUI
import Core

struct RootView: View {
    @ObservedObject var instanceManager: InstanceManager
    
    var body: some View {
        ContentView()
            .ignoresSafeArea(.all)
            .frame(minWidth: 1000, minHeight: 550)
            .environmentObject(instanceManager)
            .environmentObject(MinecraftDownloadPageViewModel())
            .environmentObject(MultiplayerViewModel())
    }
}
