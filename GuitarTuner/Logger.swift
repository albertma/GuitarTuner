//
//  logger.swift
//  GuitarTuner
//
//  Created by albertma on 2024/11/5.
//

import OSLog


extension Logger {
    static let `default` = Logger(subsystem: "com.albertma.GuitarTools", category: "General")

    func logWithDetails(_ message: String, level: OSLogType = .info, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        self.log("[\(fileName):\(line) - \(function)]: \(message)")
    }
}

let logger = Logger()
