//
//  FileDropHandler.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/5/21.
//

import Foundation
import Core

enum FileDropHandler {
    static func handle(_ url: URL, instanceManager: InstanceManager) async {
        if ModpackImportService.isModpack(url) {
            let viewModel = ModpackViewModel(instanceManager: instanceManager)
            await viewModel.importModpack(at: url, repository: instanceManager.currentRepository)
        } else {
            hint("无法识别 \(url.lastPathComponent) 的类型！", type: .critical)
        }
    }
}
