//
//  DownloadDelegate.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/24.
//

import Foundation

class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    private let destination: URL
    private let progressHandler: (@MainActor (Double) -> Void)?
    private var continuation: CheckedContinuation<Void, Error>?
    
    init(destination: URL, continuation: CheckedContinuation<Void, Error>, progressHandler: (@MainActor (Double) -> Void)?) {
        self.destination = destination
        self.progressHandler = progressHandler
        self.continuation = continuation
    }
    
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let response = downloadTask.response.flatMap({ $0 as? HTTPURLResponse }) else {
            resume(.failure(URLError.badResponse))
            return
        }
        guard (200..<300).contains(response.statusCode) else {
            resume(.failure(DownloadError.badStatusCode(code: response.statusCode)))
            return
        }
        do {
            try FileManager.default.moveItem(at: location, to: destination)
        } catch {
            resume(.failure(error))
        }
    }
    
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: (any Error)?
    ) {
        if let error {
            resume(.failure(error))
        } else {
            resume(.success(()))
        }
    }
    
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        DispatchQueue.main.async {
            DownloadSpeedManager.shared.addBytes(bytesWritten)
            if totalBytesExpectedToWrite >= 0 {
                self.progressHandler?(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite))
            }
        }
    }
    
    private func resume(_ result: Result<Void, Error>) {
        continuation?.resume(with: result)
        continuation = nil
    }
}
