import Foundation

#if canImport(CoreServices)
import CoreServices
#endif

extension URL {
    var mimeType: String {
        getMimeType() ?? "application/octet-stream"
    }

#if canImport(CoreServices)
    func getMimeType() -> String? {
        if
            let id = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as CFString, nil)?.takeRetainedValue(),
            let contentType = UTTypeCopyPreferredTagWithClass(id, kUTTagClassMIMEType)?.takeRetainedValue()
        {
            return contentType as String
        }

        return nil
    }
#else
    func getMimeType() -> String? {
        // Path to `env` on most operatin systems
        let pathToEnv = "/bin/env"

        let stdOut = Pipe()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: pathToEnv)
        process.arguments = ["file", "-E", "--brief", "--mime-type", path]
        process.standardOutput = stdOut
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            assertionFailure("File mime could not be determined: \(error)")
        }

        guard process.terminationStatus == 0 else {
            assertionFailure("File mime could not be determined: termination status \(process.terminationStatus)")
            return nil
        }

        return String(
            data: stdOut.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        )?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
#endif
}
