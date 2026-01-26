//
//  UUIDUtils.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/14.
//

import Foundation
import CryptoKit

public enum UUIDUtils {
    /// 将 `UUID` 转换成字符串。
    /// - Parameters:
    ///   - uuid: 待转换的 `UUID`。
    ///   - withHyphens: 是否插入 `-` 符号。
    public static func string(of uuid: UUID, withHyphens: Bool = true) -> String {
        let string: String = uuid.uuidString.lowercased()
        return !withHyphens ? string.replacingOccurrences(of: "-", with: "") : string
    }
    
    /// 将字符串转换成 `UUID`。
    /// - Parameter string: 待转换的字符串。
    /// - Returns: 转换后的 `UUID`。
    public static func uuid(of string: String) -> UUID? {
        return try? uuidThrowing(of: string)
    }
    
    /// 将字符串转换成 `UUID`。
    /// - Parameter string: 待转换的字符串。
    /// - Returns: 转换后的 `UUID`。
    public static func uuidThrowing(of string: String) throws -> UUID {
        // 只简单校验长度并插入横线，完整校验逻辑由 UUID(uuidString:) 处理
        let uuidString: String
        if string.count == 32 {
            let i0 = string.startIndex
            let i8 = string.index(i0, offsetBy: 8)
            let i12 = string.index(i0, offsetBy: 12)
            let i16 = string.index(i0, offsetBy: 16)
            let i20 = string.index(i0, offsetBy: 20)
            let i32 = string.index(i0, offsetBy: 32)
            uuidString = "\(string[i0..<i8])-\(string[i8..<i12])-\(string[i12..<i16])-\(string[i16..<i20])-\(string[i20..<i32])"
        } else if string.count == 36 {
            uuidString = string
        } else {
            throw UUIDError.invalidUUIDFormat
        }
        
        guard let uuid: UUID = .init(uuidString: uuidString) else {
            throw UUIDError.invalidUUIDFormat
        }
        return uuid
    }
    
    /// 符合 Bukkit 行为的离线玩家 UUID 生成器。
    /// https://github.com/MCLF-CN/docs/issues/7
    /// - Parameter name: 离线玩家的玩家名。
    public static func uuid(ofOfflinePlayer name: String) -> UUID {
        var arr: [UInt8] = Array(Insecure.MD5.hash(data: name.data(using: .utf8)!))
        arr[6] = (arr[6] & 0x0F) | 0x30
        arr[8] = (arr[8] & 0x3F) | 0x80
        return UUID(uuid: (
            arr[0], arr[1], arr[2], arr[3],
            arr[4], arr[5], arr[6], arr[7],
            arr[8], arr[9], arr[10], arr[11],
            arr[12], arr[13], arr[14], arr[15]
        ))
    }
}
