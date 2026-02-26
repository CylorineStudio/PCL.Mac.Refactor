//
//  OptionalExtension.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2025/11/8.
//

import Foundation

public extension Optional {
    /// 解包 `Optional` 并在值为空时抛出错误。
    /// - Parameters:
    ///   - errorMessage: 错误信息。
    /// - Returns: 解包后的值。
    func unwrap(_ errorMessage: String? = nil, file: String = #file, line: Int = #line) throws -> Wrapped {
        guard let value = self else {
            throw SimpleError(errorMessage ?? "\(file.split(separator: "/").last!):\(line) 解包失败。")
        }
        return value
    }
    
    /// 强制解包 `Optional` 并在值为空时 `fatalError`。
    /// 与 `unsafelyUnwrapped` 不同的是，`forceUnwrap()` 会提供文件名与行号。
    /// - Parameters:
    ///   - errorMessage: 错误信息。
    /// - Returns: 解包后的值。
    func forceUnwrap(_ errorMessage: String? = nil, file: String = #file, line: Int = #line) -> Wrapped {
        guard let value = self else {
            fatalError(errorMessage ?? "\(file.split(separator: "/").last!):\(line) 强制解包失败。")
        }
        return value
    }
}
