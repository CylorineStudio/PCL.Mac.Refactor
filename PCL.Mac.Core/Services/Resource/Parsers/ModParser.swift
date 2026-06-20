//
//  ModParser.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/6/16.
//

import Foundation
import ZIPFoundation
import TOMLDecoder

enum ModParser: ResourceParser {
    private static  let tomlDecoder: TOMLDecoder = .init()
    
    static let type: ResourceType = .mod
    
    private static let metaFiles: [String] = [
        "fabric.mod.json",
        "META-INF/mods.toml",
        "META-INF/neoforge.mods.toml"
    ]
    
    static func canHandle(fileURL: URL, archive: Archive) -> Bool {
        return metaFiles.contains { archive[$0] != nil }
    }
    
    static func parse(fileURL: URL, archive: Archive, remoteInfo: ResourceRemoteLookupService.RemoteResourceInfo?) -> ResourceParseResult? {
        var jarManifest: [String: String] = [:]
        if let entry = archive["META-INF/MANIFEST.MF"] {
            do {
                let data = try archive.extract(entry)
                guard let content = String(data: data, encoding: .utf8) else { throw SimpleError("解码字符串失败。") }
                jarManifest = JarUtils.parseManifest(content)
            } catch {
                err("加载 MANIFEST.MF 失败：\(error.localizedDescription)")
            }
        }

        var loaders: [ModLoader] = []
        var meta: ModMeta?

        for (path, loader, type) in [
            ("fabric.mod.json", loadFabric(from:), ModLoader.fabric),
            ("META-INF/mods.toml", { try self.loadForge(from: $0, jarManifest: jarManifest) }, .forge),
            ("META-INF/neoforge.mods.toml", { try self.loadForge(from: $0, jarManifest: jarManifest) }, .neoforge)
        ] {
            if let entry = archive[path] {
                do {
                    let data = try archive.extract(entry)
                    let parsedMeta = try loader(data)
                    loaders.append(type)
                    if meta == nil { meta = parsedMeta }
                } catch let error as DecodingError {
                    err("解析模组元数据失败：\(error)")
                } catch {
                    err("解压 \(path) 失败：\(error.localizedDescription)")
                }
            }
        }

        guard let meta else { return nil }
        return .init(
            name: meta.name ?? remoteInfo?.name ?? meta.id,
            version: meta.version,
            description: meta.description ?? remoteInfo?.description,
            iconPath: meta.icon,
            loaders: loaders
        )
    }
    
    
    private static func loadFabric(from data: Data) throws -> ModMeta {
        let fabricMeta: FabricMeta = try JSONDecoder.shared.decode(FabricMeta.self, from: data)
        return .init(
            id: fabricMeta.id,
            name: fabricMeta.name,
            description: fabricMeta.description,
            version: fabricMeta.version,
            icon: fabricMeta.icon
        )
    }
    
    private static func loadForge(from data: Data, jarManifest: [String: String]) throws -> ModMeta {
        var values: [String: String] = [:]
        
        if let version = jarManifest["Implementation-Version"] {
            values["file.jarVersion"] = version
        }
        
        let forgeMeta: ForgeMeta = try tomlDecoder.decode(ForgeMeta.self, from: data)
        return .init(
            id: forgeMeta.modId,
            name: forgeMeta.displayName,
            description: forgeMeta.description,
            version: forgeMeta.version.replacingPlaceholders(with: values, dollarPrefix: true),
            icon: forgeMeta.logoFile
        )
    }
    
    private struct ModMeta {
        let id: String
        let name: String?
        let description: String?
        let version: String
        let icon: String?
    }
    
    private struct FabricMeta: Codable {
        let schemaVersion: Int
        let id: String
        let version: String
        let name: String?
        let description: String?
        let icon: String?
    }
    
    private struct ForgeMeta: Decodable {
        let modId: String
        let version: String
        let displayName: String?
        let description: String?
        let logoFile: String?
        
        private enum CodingKeys: CodingKey {
            case mods
        }
        
        private enum ModCodingKeys: CodingKey {
            case modId, version, displayName, description, logoFile
        }
        
        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            var modsContainer = try container.nestedUnkeyedContainer(forKey: .mods)
            
            let first = try modsContainer.nestedContainer(keyedBy: ModCodingKeys.self)
            self.modId = try first.decode(String.self, forKey: .modId)
            self.version = try first.decode(String.self, forKey: .version)
            self.displayName = try first.decodeIfPresent(String.self, forKey: .displayName)
            self.description = try first.decodeIfPresent(String.self, forKey: .description)
            self.logoFile = try first.decodeIfPresent(String.self, forKey: .logoFile)
        }
    }
}
