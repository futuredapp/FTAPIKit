import Foundation
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

extension URL {
    var mimeType: String {
        let fallback = "application/octet-stream"

        #if os(Linux)
        return linuxMimeType(for: path) ?? fallback
        #else
        return uniformMimeType(for: pathExtension) ?? fallback
        #endif
    }

    #if canImport(UniformTypeIdentifiers)
    private func uniformMimeType(for fileExtension: String) -> String? {
        UTType(filenameExtension: fileExtension)?.preferredMIMEType
    }
    #endif

    #if os(Linux)
    private func linuxMimeType(for path: String) -> String? {
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
