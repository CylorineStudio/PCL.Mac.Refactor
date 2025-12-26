//
//  JSONCoderExtension.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/20.
//

import Foundation

public extension JSONDecoder {
    static let shared: JSONDecoder = {
        let decoder: JSONDecoder = .init()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

public extension JSONEncoder {
    static let shared: JSONEncoder = {
        let encoder: JSONEncoder = .init()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]
        return encoder
    }()
}
