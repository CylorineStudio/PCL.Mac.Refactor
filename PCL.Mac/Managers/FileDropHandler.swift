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
            return
        }
        
        let resourceLoadService = ResourceLoadService(
            remoteLookupService: .init(curseforgeClient: .init(apiKey: Secrets.shared.curseforgeApiKey ?? "")),
            cache: .shared
        )
        if let resource = try? await resourceLoadService.load(at: url) {
            guard let instance = await instanceManager.currentInstance else {
                hint("请先选择一个实例！", type: .critical)
                return
            }
            if resource.type == .mod && instance.modLoader == nil {
                hint("该实例不支持安装模组！", type: .critical)
                return
            }
            
            let directoryName = resource.type.saveDirectory!
            do {
                try FileManager.default.copyItem(at: url, to: instance.url.appending(path: "\(directoryName)/\(url.lastPathComponent)"))
                hint("添加\(resource.type.localizedName) \(resource.name) 成功！", type: .finish)
            } catch {
                err("复制\(resource.type.localizedName)失败：\(error.localizedDescription)")
                hint("复制\(resource.type.localizedName)失败：\(error.localizedDescription)", type: .critical)
            }
            return
        }
        
        hint("无法识别 \(url.lastPathComponent) 的类型！", type: .critical)
    }
}
