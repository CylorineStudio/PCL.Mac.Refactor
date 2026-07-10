//
//  MySelect.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/7/8.
//

import SwiftUI

struct MySelect<Entry: Hashable & CustomStringConvertible>: View {
    @State private var hovered: Bool = false
    @State private var presented: Bool = false
    @State private var panel: SelectPanel?
    @State private var rect: NSRect = .zero
    @State private var observer: NSObjectProtocol?
    
    @Binding private var selected: Entry
    
    private let entries: [Entry]
    
    init(_ selected: Binding<Entry>, entries: [Entry]) {
        self._selected = selected
        self.entries = entries
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        recalculateRect(proxy: proxy)
                    }
                    .onChange(of: proxy.frame(in: .global)) { _ in
                        close()
                        presented = false
                        recalculateRect(proxy: proxy)
                    }
            }
            
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(foregroundColor, lineWidth: 1.5, antialiased: false)
                .background(backgroundColor)
                .allowsHitTesting(false)
            
            HStack {
                MyText(selected.description)
                
                Spacer(minLength: 0)
                
                Image(.btnFold)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 8)
                    .rotationEffect(.degrees(presented ? -180 : 0), anchor: .center)
                    .animation(.spring(response: 0.35), value: presented)
                    .foregroundStyle(foregroundColor)
                    .padding(.trailing, 2)
            }
            .padding(.horizontal, 6)
        }
        .frame(height: 26)
        .contentShape(RoundedRectangle(cornerRadius: 4))
        .onTapGesture {
            presented.toggle()
        }
        .onHover { hovered = $0 }
        .animation(.linear(duration: 0.1), value: hovered)
        .onChange(of: presented) { newValue in
            close()
            if newValue {
                let hostingView = NSHostingView(rootView: PopupView(entries: entries, selectedEntry: selected) { entry in
                    selected = entry
                    presented = false
                    close()
                })
                
                let panel = SelectPanel(
                    contentRect: rect,
                    styleMask: [],
                    backing: .buffered,
                    defer: false
                )
                panel.contentView = hostingView
                panel.backgroundColor = .clear
                panel.hidesOnDeactivate = true
                
                self.observer = NotificationCenter.default.addObserver(
                    forName: NSWindow.didResignKeyNotification,
                    object: panel,
                    queue: .main
                ) { _ in
                    self.presented = false
                    self.close()
                }
                
                panel.makeKeyAndOrderFront(nil)
                
                self.panel = panel
            }
        }
        .onDisappear {
            close()
        }
    }
    
    private var foregroundColor: Color {
        hovered ? .color4 : .color5
    }
    
    private var backgroundColor: Color {
        hovered ? .color7 : .white.opacity(0.5)
    }
    
    private func close() {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
            self.observer = nil
        }
        panel?.close()
        panel = nil
    }
    
    private func recalculateRect(proxy: GeometryProxy) {
        guard let window = NSApplication.shared.windows.first,
              let contentView = window.contentView else { return }
        
        let global = proxy.frame(in: .global)
        let contentHeight = contentView.bounds.height
        let popupHeight = proxy.size.height * min(CGFloat(entries.count), 5.5)
        let rectInWindow = NSRect(
            x: global.minX,
            y: contentHeight - (global.minY - 1) - proxy.size.height - popupHeight,
            width: global.width,
            height: popupHeight
        )
        rect = window.convertToScreen(rectInWindow)
    }
}

private struct PopupView<Entry: Hashable & CustomStringConvertible>: View {
    @State private var hoveredEntry: Entry?
    private let entries: [Entry]
    private let selectedEntry: Entry
    private let onSelect: (Entry) -> Void
    
    init(entries: [Entry], selectedEntry: Entry, onSelect: @escaping (Entry) -> Void) {
        self.entries = entries
        self.selectedEntry = selectedEntry
        self.onSelect = onSelect
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(.white)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(entries, id: \.self) { entry in
                        Group {
                            MyText(entry.description)
                                .padding(.leading, 6)
                        }
                        .frame(height: 26)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(.rect)
                        .background(selectedEntry == entry ? Color.color6 : hoveredEntry == entry ? .color7 : .clear)
                        .onTapGesture {
                            onSelect(entry)
                        }
                        .onHover { hovered in
                            if hovered {
                                hoveredEntry = entry
                            } else if hoveredEntry == entry {
                                hoveredEntry = nil
                            }
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 4))
            
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(Color.color4, lineWidth: 1.5, antialiased: false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.2), value: hoveredEntry)
    }
}

private class SelectPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

#Preview {
    MySelect(.constant("entry0"), entries: Array(0..<10).map { "entry\($0)" })
        .padding()
}
