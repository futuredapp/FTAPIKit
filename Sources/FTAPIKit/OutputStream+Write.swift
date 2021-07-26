import Foundation
#if canImport(os)
import os
#endif

#if os(Linux)
public enum LinuxStreamError: Error {
    case streamIsInErrorState
}
#endif

extension Stream {
    func throwErrorIfStreamHasError() throws {
        #if os(Linux)
            if streamStatus == .error {
                throw LinuxStreamError.streamIsInErrorState
            }
        #else
            if let error = streamError {
                throw error
            }
        #endif
    }
}

extension OutputStream {
    private static let streamBufferSize = memoryPageSize()

    /// We want our buffer to be as close to page size as possible. Therefore we use
    /// POSIX API to get pagesize. The alternative is using compiler private macro which
    /// is less explicit.
    ///
    /// In case os can't be imported from some reason, fallback to 4 KiB size.
    private static func memoryPageSize() -> Int {
        #if canImport(os)
        return Int(getpagesize())
        #else
        return 4_096
        #endif
    }

    func write(inputStream: InputStream) throws {
        inputStream.open()
        defer { inputStream.close() }

        while inputStream.hasBytesAvailable {
            var buffer = [UInt8](repeating: 0, count: OutputStream.streamBufferSize)
            let bytesRead = inputStream.read(&buffer, maxLength: OutputStream.streamBufferSize)

            try inputStream.throwErrorIfStreamHasError()

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

            try throwErrorIfStreamHasError()

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
