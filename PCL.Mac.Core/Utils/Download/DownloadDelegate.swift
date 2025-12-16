//
//  DownloadDelegate.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/24.
//

import Foundation

class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        // 由 SingleFileDownloader 处理文件移动
    }
    
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        DownloadSpeedManager.shared.addBytes(bytesWritten)
    }
}
