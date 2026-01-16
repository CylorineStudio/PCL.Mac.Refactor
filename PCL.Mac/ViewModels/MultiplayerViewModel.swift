//
//  MultiplayerViewModel.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/15.
//

import Foundation
import SwiftScaffolding
import Core

class MultiplayerViewModel: ObservableObject {
    @Published public var state: State = .ready
    private var server: ScaffoldingServer?
    
    public enum State: Equatable {
        case ready
        case failed(message: String)
        
        case searchingMinecraft, creatingRoom, hostReady
        case joiningRoom, memberReady
    }
    
    public enum Error: LocalizedError {
        case invalidStage
    }
}
