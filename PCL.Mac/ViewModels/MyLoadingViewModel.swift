//
//  MyLoadingViewModel.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/7.
//

import Foundation

class MyLoadingViewModel: ObservableObject {
    @Published var isFailed: Bool = false
    @Published var text: String
    private let initialText: String
    
    init(text: String) {
        self.text = text
        self.initialText = text
    }
    
    func fail(with message: String) {
        isFailed = true
        text = message
    }
    
    func reset() {
        text = initialText
        isFailed = false
    }
}
