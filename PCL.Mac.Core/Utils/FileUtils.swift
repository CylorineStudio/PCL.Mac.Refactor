//
//  FileUtils.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2025/11/22.
//

import Foundation
import CryptoKit

public enum FileUtils {
    /// 通用文件哈希获取。
    /// - Parameters:
    ///   - url: 文件的 URL。
    ///   - hashFunction: 零参构造的哈希函数类型 (如 `SHA256.self`)。
    /// - Returns: 哈希结果的 hex 字符串。
    public static func hash<H: HashFunction>(of url: URL, using hashFunction: H.Type) throws -> String {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw CocoaError(.fileNoSuchFile)
        }
        let handle: FileHandle = try .init(forReadingFrom: url)
        defer { try? handle.close() }
        
        var hasher: H = .init()
        while try autoreleasepool(invoking: {
            if let data = try handle.read(upToCount: 1024 * 1024), !data.isEmpty {
                hasher.update(data: data)
                return true
            } else {
                return false
            }
        }) { }
        let digest: H.Digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    /// SHA-1
    public static func sha1(of url: URL) throws -> String {
        try hash(of: url, using: Insecure.SHA1.self)
    }
    
    /// SHA-256
    public static func sha256(of url: URL) throws -> String {
        try hash(of: url, using: SHA256.self)
    }
    
    /// SHA-512
    public static func sha512(of url: URL) throws -> String {
        try hash(of: url, using: SHA512.self)
    }
    
    public static func checkFile(at url: URL, with checksums: [String: String]) throws -> Bool {
        for (algorithm, value) in checksums {
            let hash: String? = switch algorithm {
            case "sha1": try sha1(of: url)
            case "sha256": try sha256(of: url)
            case "sha512": try sha512(of: url)
            default: nil
            }
            guard let hash else { continue }
            guard hash == value else { return false }
        }
        return true
    }
    
    public static func check(_ item: DownloadItem) throws -> Bool {
        guard let checksums = item.checksums else { return true }
        return try checkFile(at: item.destination, with: checksums)
    }
    
    public static func isExecutable(at url: URL) -> Bool {
        return Architecture.architecture(of: url) != .unknown
    }
}
