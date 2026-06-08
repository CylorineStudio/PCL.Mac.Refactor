//
//  ResourceDisplayModel.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/6/7.
//

import Foundation
import AppKit
import Core

struct ModDisplayModel {
    let id: UUID = .init()
    let name: String
    let version: String
    let description: String
    let icon: ListItem.Image
    
    init(name: String, version: String, description: String, icon: ListItem.Image?) {
        self.name = name
        self.version = version
        self.description = description
        self.icon = icon ?? .resource(.iconModLogo)
    }
    
    init(_ mod: Mod) {
        let icon: ListItem.Image?
        if let modIcon = mod.icon {
            switch modIcon {
            case .archiveEntry(_, let globalHash):
                if let data = (try? ModCache.shared.icon(forHash: globalHash)),
                   let nsImage = NSImage(data: data) {
                    icon = .nsImage(nsImage)
                } else {
                    icon = nil
                }
            case .network(let url):
                icon = .network(url)
            }
        } else {
            icon = nil
        }
        
        self.init(
            name: mod.name,
            version: mod.version,
            description: mod.description ?? "",
            icon: icon
        )
    }
}
