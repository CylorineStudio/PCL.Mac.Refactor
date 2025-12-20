//
//  AssetIndex.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/4.
//

import Foundation
import SwiftyJSON

/// https://zh.minecraft.wiki/w/散列资源文件#资源索引
public struct AssetIndex: Decodable {
    public let objects: [Object]
    
    private enum CodingKeys: String, CodingKey {
        case objects
    }
    
    public init(from decoder: any Decoder) throws {
        let contianer = try decoder.container(keyedBy: CodingKeys.self)
        let objects: [String: DecodableObject] = try contianer.decode([String: DecodableObject].self, forKey: .objects)
        self.objects = objects.map { Object(path: $0, hash: $1.hash, size: $1.size) }
    }
    
    public struct Object {
        public let path: String
        public let hash: String
        public let size: Int
    }
    
    // MARK: - Decodables
    
    private struct DecodableObject: Decodable {
        public let hash: String
        public let size: Int
    }
}
