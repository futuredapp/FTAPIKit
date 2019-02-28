//
//  MultipartInputStream.swift
//  FTAPIKit
//
//  Created by Matěj Kašpar Jirásek on 25/02/2019.
//  Copyright © 2019 FUNTASTY Digital s.r.o. All rights reserved.
//

import Foundation

struct MultipartFormData {

    private let parts: [MultipartBodyPart]
    private let boundaryData: Data
    private let temporaryUrl: URL = makeTemporaryUrl()

    init(parts: [MultipartBodyPart], boundary: String) {
        self.parts = parts
        self.boundaryData = Data(boundary.utf8)
    }

    private static func makeTemporaryUrl() -> URL {
        return URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("body")
    }

    func inputStream() throws -> InputStream {
        guard let inputStream = InputStream(url: temporaryUrl) else {
            throw APIError.uploadFileNotLoaded
        }
        return inputStream
    }

    private func outputStream() throws {
        guard let outputStream = OutputStream(url: temporaryUrl, append: false) else {
            throw APIError.uploadFileNotLoaded
        }
        outputStream.open()
        defer {
            outputStream.close()
        }
        for part in parts {
            try outputStream.write(data: boundaryData)
            try outputStream.writeLine()
            try write(headers: part.headers, to: outputStream)
            try outputStream.writeLine()
            try outputStream.write(inputStream: part.inputStream)
            try outputStream.writeLine()
        }
        try outputStream.write(data: boundaryData)
    }

    private func write(headers: [String: String], to outputStream: OutputStream) throws {
        for (key, value) in headers {
            try outputStream.writeLine(string: "\(key): \(value)")
        }
    }
}
