//
//  FileUtils.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/22.
//

import Foundation
import CryptoKit

public enum FileUtils {
    /// 获取文件的 SHA-1 校验和。
    /// - Parameter url: 文件的 `URL`。
    /// - Returns: 文件的 SHA-1。
    public static func sha1(of url: URL) throws -> String {
        let handle: FileHandle = try .init(forReadingFrom: url)
        defer { try? handle.close() }
        
        var hasher: Insecure.SHA1 = .init()
        while try autoreleasepool(invoking: {
            if let data = try handle.read(upToCount: 1024 * 1024), !data.isEmpty {
                hasher.update(data: data)
                return true
            } else {
                return false
            }
        }) { }
        let digest: Insecure.SHA1.Digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    public static func isExecutable(at url: URL) -> Bool {
        return Architecture.architecture(of: url) != .unknown
    }
}
