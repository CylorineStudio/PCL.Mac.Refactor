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
    
    init(text: String) {
        self.text = text
    }
    
    func fail() {
        isFailed = true
    }
}
