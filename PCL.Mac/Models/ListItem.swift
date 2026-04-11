//
//  ListItem.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/1/26.
//

import SwiftUI

struct ListItem {
    public let image: Image?
    public let imageSize: CGFloat
    public let name: String
    public let description: String?
    
    init(image: Image? = nil, imageSize: CGFloat = 36, name: String, description: String?) {
        self.image = image
        self.imageSize = imageSize
        self.name = name
        self.description = description
    }
    
    init(image: ImageResource?, imageSize: CGFloat = 36, name: String, description: String?) {
        self.init(image: image.map(Image.resource), imageSize: imageSize, name: name, description: description)
    }
    
    enum Image {
        case resource(ImageResource)
        case nsImage(NSImage)
    }
}
