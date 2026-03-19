//
//  ResourceInstallViewModel.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/3/19.
//

import Foundation
import Core

class ResourceInstallViewModel: ObservableObject {
    public typealias VersionList = [(VersionMapKey, [ProjectVersionModel])]
    
    @Published public var versionList: VersionList?
    @Published public var loaded: Bool = false
    public let project: ProjectListItemModel
    public let loadingVM: MyLoadingViewModel = .init(text: "加载中")
    
    public init(project: ProjectListItemModel) {
        self.project = project
    }
    
    public func load() async throws {
        let versions: [ModrinthVersion] = try await ModrinthAPIClient.shared.versions(ofProject: project.id)
        
        var versionMap: [VersionMapKey: [ProjectVersionModel]] = [:]
        for version in versions {
            let value: ProjectVersionModel = .init(
                id: version.id,
                name: version.name,
                version: version.versionNumber,
                downloads: ProjectListItemModel.formatDownloads(version.downloads),
                datePublished: ProjectListItemModel.formatLastUpdate(version.datePublished),
                requiredDependencies: [],
                type: version.type,
                primaryFile: version.files.filter(\.primary).first
            )
            
            var keys: [VersionMapKey] = []
            for gameVersion in version.gameVersions {
                if let type = CoreState.versionManifest.version(for: gameVersion)?.type,
                   type != .release {
                    continue
                }
                if version.loaders.isEmpty {
                    keys.append(.init(loader: nil, version: .init(gameVersion)))
                    continue
                }
                for loader in version.loaders {
                    keys.append(.init(loader: loader, version: .init(gameVersion)))
                }
            }
            for key in keys {
                if !versionMap.keys.contains(key) {
                    versionMap[key] = []
                }
                versionMap[key]?.append(value)
            }
        }
        
        let versionList: VersionList = versionMap.map { ($0, $1) }.sorted(by: { $0.0 > $1.0 })
        await MainActor.run {
            self.versionList = versionList
            self.loaded = true
        }
    }
    
    public struct VersionMapKey: Hashable, Equatable, Comparable, Identifiable, CustomStringConvertible {
        public let id: UUID = .init()
        public let loader: ModLoader?
        public let version: MinecraftVersion
        
        public static func < (lhs: Self, rhs: Self) -> Bool {
            if lhs.version != rhs.version {
                return lhs.version < rhs.version
            } else {
                return (lhs.loader?.index ?? 0) < (rhs.loader?.index ?? 0)
            }
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(loader)
            hasher.combine(version)
        }
        
        public static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.description == rhs.description
        }
        
        public var description: String {
            if let loader {
                return "\(loader) \(version)"
            }
            return version.description
        }
    }
}
