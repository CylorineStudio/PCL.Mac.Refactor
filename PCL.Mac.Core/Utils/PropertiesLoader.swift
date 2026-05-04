//
//  PropertiesLoader.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/5/4.
//

import Foundation

public enum PropertiesLoader {
    public static func load(at url: URL) throws(LoadError) -> [String: String] {
        let data: Data
        do {
            data = try .init(contentsOf: url)
        } catch {
            throw .failedToReadFile(underlying: error)
        }
        
        guard let content = String(data: data, encoding: .utf8) else {
            throw .failedToDecodeContent
        }
        
        return try load(from: content)
    }
    
    public static func load(from string: String) throws(LoadError) -> [String: String] {
        var result: [String: String] = [:]
        let lines = string.split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !$0.starts(with: "#") }
        
        for line in lines {
            let parts = line.split(separator: "=", maxSplits: 1)
                .map { String.init($0)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .trimmingCharacters(in: .init(charactersIn: "\"")) }
            guard parts.count == 2 else {
                throw .invalidLine(line: line)
            }
            
            let (key, value) = (parts[0], parts[1])
            
            guard result[key] == nil else {
                throw .duplicateKey(key: key)
            }
            result[key] = value
        }
        
        return result
    }
    
    public enum LoadError: LocalizedError {
        case failedToReadFile(underlying: Error)
        case failedToDecodeContent
        case invalidLine(line: String)
        case duplicateKey(key: String)
        
        public var errorDescription: String? {
            switch self {
            case .failedToReadFile(let underlying):
                "读取文件失败：\(underlying.localizedDescription)"
            case .failedToDecodeContent:
                "解码文件内容失败。"
            case .invalidLine(let line):
                "无效的行：\"\(line)\""
            case .duplicateKey(let key):
                "包含重复键：\"\(key)\""
            }
        }
    }
}
