//
//  JavaSettingsViewModel.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/3/6.
//

import Foundation
import Core
import Combine

class JavaSettingsViewModel: ObservableObject {
    @Published public var javaList: [ListItem] = []
    
    private var cancellables: [AnyCancellable] = []
    
    init() {
        JavaManager.shared.$javaRuntimes
            .map {
                $0.sorted { $0.version > $1.version }.map { ListItem(name: $0.description, description: $0.executableURL.path) }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.javaList, on: self)
            .store(in: &cancellables)
    }
}
