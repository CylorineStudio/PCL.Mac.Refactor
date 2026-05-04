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
            guard parts.count == 2 else {
                throw .invalidLine(line: line)
            }
            
            let (key, value) = (String(parts[0]), String(parts[1]))
            
            guard !result.keys.contains(key) else {
                throw .duplicateKey(key: value)
            }
            result[key] = value.trimmingCharacters(in: .init(charactersIn: "\""))
        }
        
        return result
    }
    
    public enum LoadError: LocalizedError {
        case failedToReadFile(underlying: Error)
        case failedToDecodeContent
        case invalidLine(line: String)
        case duplicateKey(key: String)
    }
}
