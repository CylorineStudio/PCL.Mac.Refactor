//
//  JarUtils.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/2/17.
//

import Foundation
import ZIPFoundation

public enum JarUtils {
    public static func mainClass(of jarURL: URL) throws -> String {
        let archive: Archive = try Archive(url: jarURL, accessMode: .read)
        guard let manifestEntry: Entry = archive["META-INF/MANIFEST.MF"] else {
            throw Error.missingManifest
        }
        var dataBuffer: Data = .init()
        _ = try archive.extract(manifestEntry, consumer: { (chunk) in
            dataBuffer.append(chunk)
        })
        guard let manifest: String = .init(data: dataBuffer, encoding: .utf8) else {
            throw Error.failedToDecodeManifest
        }
        
        let lines: [String] = manifest.components(separatedBy: .newlines)
        for line in lines {
            if line.starts(with: "Main-Class: ") {
                return String(line.dropFirst("Main-Class: ".count))
            }
        }
        throw Error.mainClassNotFound
    }
    
    public enum Error: LocalizedError {
        case missingManifest
        case failedToDecodeManifest
        case mainClassNotFound
        
        public var errorDescription: String? { "获取主类失败。" }
    }
}
