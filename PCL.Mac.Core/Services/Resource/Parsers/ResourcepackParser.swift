//
//  ResourcepackParser.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/6/16.
//

import Foundation
import ZIPFoundation

enum ResourcepackParser: ResourceParser {
    static let type: ResourceType = .resourcepack
    
    static func canHandle(fileURL: URL, archive: Archive) -> Bool {
        return archive["pack.mcmeta"] != nil
    }
    
    static func parse(fileURL: URL, archive: Archive, remoteInfo: ResourceRemoteLookupService.RemoteResourceInfo?) -> ResourceParseResult? {
        guard let entry = archive["pack.mcmeta"] else { return nil }
        
        let meta: PackMeta
        do {
            let data = try archive.extract(entry)
            meta = try JSONDecoder.shared.decode(PackMeta.self, from: data)
        } catch {
            err("解析 pack.mcmeta 失败：\(error.localizedDescription)")
            if error is DecodingError {
                debug(error)
            }
            return nil
        }
        
        return .init(
            name: fileURL.deletingAllPathExtensions().lastPathComponent,
            version: remoteInfo?.version,
            description: remoteInfo?.description ?? meta.description,
            iconPath: "pack.png",
            loaders: []
        )
    }
    
    private struct PackMeta: Decodable {
        let description: String?
        
        private enum CodingKeys: CodingKey { case pack }
        private enum PackCodingKeys: CodingKey { case description }
        
        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let packContainer = try container.nestedContainer(keyedBy: PackCodingKeys.self, forKey: .pack)
            
            if let description = try? packContainer.decodeIfPresent(String.self, forKey: .description) {
                self.description = description
            } else {
                self.description = nil
            }
        }
    }
}
