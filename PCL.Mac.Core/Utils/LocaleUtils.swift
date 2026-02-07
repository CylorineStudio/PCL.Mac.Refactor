//
//  LocaleUtils.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/2/4.
//

import Foundation
import CoreLocation

public enum LocaleUtils {
    public static func isSystemLocaleChinese() -> Bool {
        return Locale.current.identifier == "zh_CN"
    }
    
    public static func isInChinaMainland() async -> Bool {
        do {
            let response: String = try String(data: await Requests.get("https://www.cloudflare-cn.com/cdn-cgi/trace").data, encoding: .utf8).unwrap("解析字符串失败。")
            return response.contains("\nloc=CN\n")
        } catch {
            err("获取地区失败：\(error.localizedDescription)")
            return false
        }
    }
}
