//
//  ModpackIndex.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/5/2.
//

import Foundation

public struct ModpackIndex {
    public protocol File {
        func fetchInfo() async throws
        
        var url: URL? { get }
        var path: String? { get }
        var checksums: [String: String]? { get }
    }
    
    public enum Format: CustomStringConvertible {
        case modrinth, curseforge, mcbbs
        
        public var description: String {
            switch self {
            case .modrinth: "Modrinth"
            case .curseforge: "CurseForge"
            case .mcbbs: "MCBBS"
            }
        }
    }
    
    public let format: Format
    
    public let name: String
    public let version: String
    public let author: String?
    public let description: String?
    
    public let minecraftVersion: MinecraftVersion
    public let modLoader: (ModLoader, String)?
    public let files: [File]
    public let overridesDirectories: [String]
    
    public var dependencyInfo: String {
        var info = "Minecraft \(minecraftVersion)"
        if let modLoader {
            info += ", \(modLoader.0.description) \(modLoader.1)"
        }
        return info
    }
}

public extension ModpackIndex {
    struct RegularFile: File {
        public let url: URL?
        public let path: String?
        public let checksums: [String: String]?
        
        public init(url: URL, path: String, checksums: [String : String]) {
            self.url = url
            self.path = path
            self.checksums = checksums
        }
        
        public func fetchInfo() async throws { }
    }
    
    class CurseForgeFile: File {
        private let client: CurseForgeAPIClient
        private let providedURL: URL?
        private let projectId: Int
        private let fileId: Int
        
        private var cachedMod: CurseForgeMod?
        private var cachedModFile: CurseForgeModFile?
        private var infoFetched: Bool = false
        
        public init(client: CurseForgeAPIClient, url: URL?, projectId: Int, fileId: Int) {
            self.client = client
            self.providedURL = url
            self.projectId = projectId
            self.fileId = fileId
        }
        
        public convenience init(client: CurseForgeAPIClient, file: CurseForgeModpackIndex.File) {
            self.init(client: client, url: file.url, projectId: file.projectId, fileId: file.fileId)
        }
        
        public var url: URL? {
            if let providedURL {
                return providedURL
            }
            return cachedModFile?.downloadURL
        }
        
        public var path: String? {
            guard let cachedMod, let cachedModFile, let type = cachedMod.projectType else { return nil }
            guard let directory: String = switch type {
            case .mod: "mods"
            case .modpack: nil
            case .resourcepack: "resourcepacks"
            case .shader: "shaderpacks"
            } else { return nil }
            return "\(directory)/\(cachedModFile.fileName)"
        }
        
        public var checksums: [String: String]? {
            return cachedModFile?.checksums
        }
        
        public func fetchInfo() async throws {
            if infoFetched { return }
            infoFetched = true
            
            guard let mod = try await client.mod(id: projectId) else {
                throw SimpleError("资源 \(projectId) 不存在")
            }
            guard let file = try await client.modFile(modId: projectId, fileId: fileId) else {
                throw SimpleError("资源文件 \(projectId)/\(fileId) 不存在")
            }
            cachedMod = mod
            cachedModFile = file
        }
    }
}
