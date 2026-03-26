//
//  OtherSettingsPage.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/3/26.
//

import SwiftUI
import Core

struct OtherSettingsPage: View {
    var body: some View {
        CardContainer {
            MyCard("调试", foldable: false) {
                HStack {
                    MyButton("导出日志") {
                        do {
                            let url: URL = try SettingsViewModel.shared.exportLogs()
                            NSWorkspace.shared.activateFileViewerSelecting([url])
                        } catch {
                            err("导出日志失败：\(error.localizedDescription)")
                            hint("导出日志失败：\(error.localizedDescription)", type: .critical)
                        }
                    }
                    .frame(width: 150)
                    Spacer()
                }
                .frame(height: 40)
            }
            MyCard("启动器更新", foldable: false) {
                HStack {
                    MyButton("检查更新") {
                        UpdateService.shared.runInteractiveUpdateFlow(manually: true)
                    }
                    .frame(width: 150)
                    Spacer()
                }
                .frame(height: 40)
            }
        }
    }
}
