//
//  FileUtils.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/22.
//

import Foundation
import CryptoKit

public enum FileUtils {
    public static func getSHA1(_ url: URL) throws -> String {
        let data: Data = try Data(contentsOf: url)
        let digest: Insecure.SHA1.Digest = Insecure.SHA1.hash(data: data)
        let hexString: String = digest.map { byte in
            String(format: "%02x", byte)
        }.joined()
        return hexString
    }
}
