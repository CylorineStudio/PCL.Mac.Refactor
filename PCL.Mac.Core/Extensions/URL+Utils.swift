//
//  URL+Utils.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/6/16.
//

import Foundation

public extension URL {
    func deletingAllPathExtensions() -> URL {
        var url = self
        while url.pathExtension != "" {
            url = url.deletingPathExtension()
        }
        return url
    }
}
