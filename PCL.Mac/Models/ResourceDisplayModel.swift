//
//  ResourceDisplayModel.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/6/7.
//

import Foundation
import AppKit
import Core

class ResourceDisplayModel: ObservableObject, Hashable, Equatable {
    let id: UUID = .init()
    let name: String
    let version: String?
    let description: String
    let tags: [String]
    let icon: ListItem.Image
    let sources: [Resource.Source]
    @Published var url: URL
    @Published var disabled: Bool
    
    var fileName: String { url.lastPathComponent }
    
    init(
        name: String,
        version: String?,
        description: String,
        tags: [String],
        icon: ListItem.Image?,
        sources: [Resource.Source],
        url: URL,
        disabled: Bool
    ) {
        self.name = name
        self.version = version
        self.description = description
        self.tags = tags
        self.icon = icon ?? .resource(.iconModLogo)
        self.sources = sources
        self.url = url
        self.disabled = disabled
    }
    
    convenience init(_ url: URL, _ mod: Resource) {
        let icon: ListItem.Image?
        if let modIcon = mod.icon {
            switch modIcon {
            case .archiveEntry(_, let globalHash):
                if let data = (try? ResourceCache.shared.icon(forHash: globalHash)),
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
            description: (mod.description ?? "").replacingOccurrences(of: "\n", with: "\\n"),
            tags: mod.tags.compactMap(ProjectListItemModel.localizeTag(_:)),
            icon: icon,
            sources: mod.sources,
            url: url,
            disabled: url.pathExtension == "disabled"
        )
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
    
    static func == (lhs: ResourceDisplayModel, rhs: ResourceDisplayModel) -> Bool { lhs.url == rhs.url }
}
