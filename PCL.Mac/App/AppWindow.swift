//
//  AppWindow.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/29.
//

import SwiftUI

class AppWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    
    init() {
        super.init(
            contentRect: .init(x: 0, y: 0, width: 1000, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable, .fullSizeContentView],
            backing: .buffered, defer: false
        )
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        
        self.contentView = NSHostingView(rootView: ContentView().ignoresSafeArea(.container, edges: .top))
        
        self.setFrameAutosaveName("AppWindow")
        self.center()
    }
}
