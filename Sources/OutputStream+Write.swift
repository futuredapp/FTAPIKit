//
//  OutputStream+Write.swift
//  FTAPIKit
//
//  Created by Matěj Kašpar Jirásek on 27/02/2019.
//  Copyright © 2019 FUNTASTY Digital s.r.o. All rights reserved.
//

import Foundation

extension OutputStream {
    private static let streamBufferSize = 1024

    func write(inputStream: InputStream) throws {
        inputStream.open()
        defer { inputStream.close() }

        while inputStream.hasBytesAvailable {
            var buffer = [UInt8](repeating: 0, count: OutputStream.streamBufferSize)
            let bytesRead = inputStream.read(&buffer, maxLength: OutputStream.streamBufferSize)

            if let streamError = inputStream.streamError {
                throw streamError
            }

            if bytesRead > 0 {
                if buffer.count != bytesRead {
                    buffer = Array(buffer[0..<bytesRead])
                }
                try write(buffer: &buffer)
            } else {
                break
            }
        }
    }

    func write(data: Data) throws {
        var buffer = [UInt8](repeating: 0, count: data.count)
        data.copyBytes(to: &buffer, count: data.count)

        return try write(buffer: &buffer)
    }

    func write(buffer: inout [UInt8]) throws {
        var bytesToWrite = buffer.count

        while bytesToWrite > 0, hasSpaceAvailable {
            let bytesWritten = write(buffer, maxLength: bytesToWrite)

            if let error = streamError {
                throw error
            }

            bytesToWrite -= bytesWritten

            if bytesToWrite > 0 {
                buffer = Array(buffer[bytesWritten..<buffer.count])
            }
        }
    }

    func write(string: String) throws {
        try write(data: Data(string.utf8))
    }

    func writeLine(string: String? = nil) throws {
        if let string = string {
            try write(string: string)
        }
        try write(string: "\r\n")
    }
}
