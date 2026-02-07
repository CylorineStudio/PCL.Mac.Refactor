//
//  ListItem.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/26.
//

import SwiftUI

struct ListItem {
    public let image: String?
    public let imageSize: CGFloat
    public let name: String
    public let description: String?
    
    init(image: String? = nil, imageSize: CGFloat = 36, name: String, description: String?) {
        self.image = image
        self.imageSize = imageSize
        self.name = name
        self.description = description
    }
}
