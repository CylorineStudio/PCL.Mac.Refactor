//
//  DataManager.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/10.
//

import SwiftUI
import Core

class DataManager: ObservableObject {
    @Published var runningTasks: [AnyMyTask] = []
    var versionsLastModified: String?
}
