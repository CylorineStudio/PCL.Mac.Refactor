//
//  MyLoadingViewModel.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/1/7.
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
    
    @MainActor
    func fail(with message: String) {
        isFailed = true
        text = message
    }
    
    @MainActor
    func reset() {
        text = initialText
        isFailed = false
    }
}
