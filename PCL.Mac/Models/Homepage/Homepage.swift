//
//  Homepage.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/6/2.
//

import SwiftUI
import SWXMLHash

struct Homepage: XMLObjectDeserialization {
    struct Config: XMLObjectDeserialization {
        let trimText: Bool
        
        static func deserialize(_ element: XMLIndexer) throws -> Homepage.Config {
            let configDict: [String: String] = (element.element?.allAttributes ?? [:]).mapValues(\.text)
            return .init(
                trimText: bool(configDict, "trimText", defaultValue: false)
            )
        }
        
        private static func bool(_ configDict: [String: String], _ key: String, defaultValue: Bool) -> Bool {
            return configDict[key].flatMap(Bool.init) ?? defaultValue
        }
    }
    
    struct DeserializeContext {
        let config: Config
        let componentParser: HomepageComponentParser
    }
    
    let author: String?
    let summary: String?
    let config: Config
    let components: [any HomepageComponent]
    
    static func deserialize(_ element: XMLIndexer) throws -> Homepage {
        let config: Config = try Config.deserialize(element["config"])
        let componentParser = HomepageComponentParser(config: config)
        return .init(
            author: element.value(ofAttribute: "author"),
            summary: element.value(ofAttribute: "summary"),
            config: config,
            components: try componentParser.parseAll(element)
        )
    }
}
