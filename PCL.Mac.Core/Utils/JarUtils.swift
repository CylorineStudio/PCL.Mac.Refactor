//
//  JarUtils.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/2/17.
//

import Foundation
import ZIPFoundation

public enum JarUtils {
    public static func parseManifest(_ content: String) -> [String: String] {
        content
            .split(whereSeparator: \.isNewline)
            .reduce(into: [:]) { result, line in
                let parts = line.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
                guard parts.count == 2 else { return }
                let key = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let value = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                guard !key.isEmpty else { return }
                result[key] = value
            }
    }
    
    public static func mainClass(of jarURL: URL) throws -> String {
        let archive: Archive = try Archive(url: jarURL, accessMode: .read)
        guard let manifestEntry: Entry = archive["META-INF/MANIFEST.MF"] else {
            throw Error.missingManifest
        }
        
        let data = try archive.extract(manifestEntry)
        
        guard let content = String(data: data, encoding: .utf8) else {
            throw Error.failedToParseManifest
        }
        
        let manifest = parseManifest(content)
        guard let mainClass = manifest["Main-Class"] else { throw Error.mainClassNotFound }
        return mainClass
    }
    
    public enum Error: LocalizedError {
        case missingManifest
        case failedToParseManifest
        case mainClassNotFound
        
        public var errorDescription: String? { "获取主类失败。" }
    }
}
