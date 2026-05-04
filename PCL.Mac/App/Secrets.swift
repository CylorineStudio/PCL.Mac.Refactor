//
//  Secrets.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/5/4.
//

import Foundation
import Core

struct Secrets {
    public static let shared: Secrets = .init()
    
    public let curseforgeApiKey: String?
    
    private init() {
        do {
            let secretsURL = URLConstants.resourcesURL.appending(path: "Secrets.properties")
            let secrets = try PropertiesLoader.load(at: secretsURL)
            self.curseforgeApiKey = secrets["CURSE_FORGE_API_KEY"]
        } catch {
            err("加载 Secrets.properties 失败：\(error.localizedDescription)")
            self.curseforgeApiKey = nil
        }
    }
}
