//
//  ResourcepackParser.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/6/16.
//

import Foundation
import ZIPFoundation
import SwiftyJSON

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
            name: remoteInfo?.name ?? removingFormattingCodes(fileURL.deletingAllPathExtensions().lastPathComponent),
            version: remoteInfo?.version,
            description: remoteInfo?.description ?? meta.description.map {
                removingFormattingCodes(String($0.split(separator: "\n")[0]))
            },
            iconPath: "pack.png",
            loaders: []
        )
    }
    
    private static func removingFormattingCodes(_ string: String) -> String {
        var result = ""
        var skipNext = false
        for char in string {
            if char == "§" {
                skipNext = true
            } else if skipNext {
                skipNext = false
            } else {
                result.append(char)
            }
        }
        return result
    }
    
    private struct PackMeta: Decodable {
        let description: String?
        
        private enum CodingKeys: CodingKey { case pack }
        private enum PackCodingKeys: CodingKey { case description }
        
        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let packContainer = try container.nestedContainer(keyedBy: PackCodingKeys.self, forKey: .pack)
            
            if packContainer.contains(.description) {
                self.description = Self.parseTextComponent(from: try packContainer.decode(JSON.self, forKey: .description))
            } else {
                self.description = nil
            }
        }
        
        private static func parseTextComponent(from json: JSON) -> String {
            if let string = json.string {
                return string
            } else if let array = json.array {
                return array.map(parseTextComponent(from:)).joined()
            } else {
                var result = ""
                if let text = json["text"].string {
                    result += text
                } else if let translate = json["translate"].string {
                    result += translate
                }
                if json["extra"].exists() {
                    result += parseTextComponent(from: json["extra"])
                }
                return result
            }
        }
    }
}
