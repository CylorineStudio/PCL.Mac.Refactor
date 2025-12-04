//
//  LogManager.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/8.
//

import Foundation
import os

public class LogManager {
    public static let shared: LogManager = .init()
    private var fileHandle: FileHandle?
    private let dateFormatter: DateFormatter = {
        let formatter: DateFormatter = .init()
        formatter.dateFormat = "[yyyy-MM-dd] [HH:mm:ss.SSS]"
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        return formatter
    }()
    private let logQueue: DispatchQueue = .init(label: "PCL.Mac.Log")
    private let logger: Logger = .init()
    
    public func enableLogging(logsURL: URL) {
        let logFileURL: URL = logsURL.appending(path: "Log1.log")
        if !FileManager.default.fileExists(atPath: logsURL.path) {
            try? FileManager.default.createDirectory(at: logsURL, withIntermediateDirectories: true)
            FileManager.default.createFile(atPath: logFileURL.path, contents: nil)
        } else {
            Self.updateLogs(logsURL: logsURL)
            FileManager.default.createFile(atPath: logFileURL.path, contents: nil)
        }
        let handle: FileHandle = try! FileHandle(forWritingTo: logFileURL)
        try? handle.truncate(atOffset: 0)
        self.fileHandle = handle
    }
    
    public func log(message: Any, level: String, file: String = #file, line: Int = #line) {
        // 构建日志字符串
        let time: String = dateFormatter.string(from: Date())
        let caller: String = "\(URL(fileURLWithPath: file).lastPathComponent):\(line)"
        let content: String = String(format: "%@ [%@] %@: %@", time, level, caller, String(describing: message))
        // 输出
        switch level {
        case "WARN": logger.error("\(content)")
        case "ERROR": logger.fault("\(content)")
        case "DEBUG": logger.debug("\(content)")
        default: print(content)
        }
        // 写入文件
        if let handle = fileHandle {
            logQueue.async {
                do {
                    try handle.write(contentsOf: (content + "\n").data(using: .utf8).unwrap("无法编码日志行。"))
                } catch {
                    print("无法写入日志: \(error)")
                }
            }
        }
    }
    
    public func info(_ message: Any, file: String = #file, line: Int = #line) {
        log(message: message, level: "INFO", file: file, line: line)
    }
    
    public func warn(_ message: Any, file: String = #file, line: Int = #line) {
        log(message: message, level: "WARN", file: file, line: line)
    }
    
    public func error(_ message: Any, file: String = #file, line: Int = #line) {
        log(message: message, level: "ERROR", file: file, line: line)
    }
    
    public func debug(_ message: Any, file: String = #file, line: Int = #line) {
        log(message: message, level: "DEBUG", file: file, line: line)
    }
    
    private static func updateLogs(logsURL: URL) {
        try? FileManager.default.removeItem(at: logsURL.appending(path: "Log5.log"))
        moveLog(logsURL: logsURL, from: "Log4.log", to: "Log5.log")
        moveLog(logsURL: logsURL, from: "Log3.log", to: "Log4.log")
        moveLog(logsURL: logsURL, from: "Log2.log", to: "Log3.log")
        moveLog(logsURL: logsURL, from: "Log1.log", to: "Log2.log")
    }
    
    private static func moveLog(logsURL: URL, from source: String, to destination: String) {
        try? FileManager.default.moveItem(at: logsURL.appending(path: source), to: logsURL.appending(path: destination))
    }
}

public func log(_ message: Any, file: String = #file, line: Int = #line) { LogManager.shared.info(message, file: file, line: line) }

public func warn(_ message: Any, file: String = #file, line: Int = #line) { LogManager.shared.warn(message, file: file, line: line) }

public func err(_ message: Any, file: String = #file, line: Int = #line) { LogManager.shared.error(message, file: file, line: line) }

public func debug(_ message: Any, file: String = #file, line: Int = #line) { LogManager.shared.debug(message, file: file, line: line) }
