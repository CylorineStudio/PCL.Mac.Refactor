//
//  ArchiveUtils.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2025/11/26.
//

import Foundation
import ZIPFoundation

public enum ArchiveUtils {
    /// 判断归档中是否存在某个文件。
    /// - Parameters:
    ///   - url: 归档文件的 `URL`。
    ///   - path: 文件路径。
    /// - Returns: 一个布尔值，表示是否存在。
    public static func hasEntry(url: URL, path: String) throws -> Bool {
        return hasEntry(archive: try Archive(url: url, accessMode: .read), path: path)
    }
    
    /// 判断归档中是否存在某个文件。
    /// - Parameters:
    ///   - archive: 归档对象。
    ///   - path: 文件路径。
    /// - Returns: 一个布尔值，表示是否存在。
    public static func hasEntry(archive: Archive, path: String) -> Bool {
        return archive[path] != nil
    }
    
    /// 读取归档中某个文件的内容。
    /// - Parameters:
    ///   - url: 归档文件的 `URL`。
    ///   - path: 文件路径。
    /// - Returns: 该文件的内容。
    public static func getEntry(url: URL, path: String) throws -> Data {
        return try getEntry(archive: Archive(url: url, accessMode: .read), path: path)
    }
    
    /// 读取归档中某个文件的内容。
    /// - Parameters:
    ///   - url: 归档对象。
    ///   - path: 文件路径。
    /// - Returns: 该文件的内容。
    public static func getEntry(archive: Archive, path: String) throws -> Data {
        guard let entry = archive[path] else {
            throw Archive.ArchiveError.invalidEntryPath
        }
        var entryData: Data = .init()
        _ = try archive.extract(entry, consumer: { data in
            entryData.append(data)
        })
        return entryData
    }
}
