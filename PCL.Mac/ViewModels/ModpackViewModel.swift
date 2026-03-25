//
//  ModpackViewModel.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/3/23.
//

import Foundation
import Core
import ZIPFoundation

class ModpackViewModel {
    public func loadModpack(at url: URL) throws -> ModpackLoadResult? {
        log("正在检查整合包 \(url.path)")
        let archive: Archive
        do {
            archive = try .init(url: url, accessMode: .read)
        } catch {
            throw Error.extractFailed(underlying: error)
        }
        
        if let modrinthIndexEntry: Entry = archive["modrinth.index.json"] {
            let index: ModrinthModpackIndex = try parseIndex(modrinthIndexEntry, in: archive)
            return .init(
                name: index.name,
                version: index.versionId,
                summary: index.summary ?? "无",
                format: "Modrinth",
                dependencyInfo: index.dependencies.description,
                index: .modrinth(index)
            )
        }
        return nil
    }
    
    public struct ModpackLoadResult {
        public let name: String
        public let version: String
        public let summary: String
        public let format: String
        public let dependencyInfo: String
        public let index: ModpackIndex
    }
    
    public enum ModpackIndex {
        case modrinth(ModrinthModpackIndex)
    }
    
    public enum Error: LocalizedError {
        case extractFailed(underlying: Swift.Error)
        case failedToParseIndex(underlying: Swift.Error)
        
        public var errorDescription: String? {
            switch self {
            case .extractFailed(let underlying):
                "解压整合包文件失败：\(underlying.localizedDescription)"
            case .failedToParseIndex(let underlying):
                "解析整合包索引失败：\(underlying.localizedDescription)"
            }
        }
    }
    
    private func parseIndex<T: Codable>(_ entry: Entry, in archive: Archive) throws -> T {
        do {
            var data: Data = .init()
            _ = try archive.extract(entry, consumer: { data += $0 })
            let index: T = try JSONDecoder.shared.decode(T.self, from: data)
            log("\(entry.path) 存在且解析成功")
            return index
        } catch let error as DecodingError {
            err("\(entry.path) 存在但解析失败：\(error)")
            throw Error.failedToParseIndex(underlying: error)
        }
    }
}
