//
//  LocaleUtils.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/2/4.
//

import Foundation
import CoreLocation

public enum LocaleUtils {
    private static var inChinaMainland: Bool?
    
    /// 判断系统地区设置是否为中国大陆。
    public static func isSystemLocaleChinese() -> Bool {
        return Locale.current.identifier == "zh_CN"
    }
    
    /// 判断当前设备的物理位置是否在中国大陆。
    ///
    /// 位置查询使用了 [CloudFlare API](https://www.cloudflare-cn.com/cdn-cgi/trace) ，**可能会包含港澳台区域**。
    /// - Parameter strict: 查询失败时是否返回 `false`。
    public static func isInChinaMainland(strict: Bool = true, useCache: Bool = true) async -> Bool {
        if let inChinaMainland, useCache {
            return inChinaMainland
        }
        do {
            let response: String = try String(
                data: await Requests.get("https://www.cloudflare-cn.com/cdn-cgi/trace", noCache: true).data,
                encoding: .utf8
            ).unwrap("解析字符串失败。")
            let inChinaMainland = response.contains("\nloc=CN\n")
            Self.inChinaMainland = inChinaMainland
            return inChinaMainland
        } catch {
            err("获取地区失败：\(error.localizedDescription)")
            return !strict
        }
    }
}
