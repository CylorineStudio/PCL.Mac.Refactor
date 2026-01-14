//
//  UUIDUtils.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/14.
//

import Foundation

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
}
