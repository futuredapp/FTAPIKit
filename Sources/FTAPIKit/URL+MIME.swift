import Foundation
#if canImport(CoreServices)
import CoreServices
#endif
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

extension URL {
    var mimeType: String {
        let fallback = "application/octet-stream"

        #if os(Linux)
        return linuxMimeType(path) ?? fallback
        #else
        if #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *) {
            return uniformMimeType(for: pathExtension) ?? fallback
        } else {
            return coreServicesMimeType(for: pathExtension) ?? fallback
        }
        #endif
    }

    #if canImport(UniformTypeIdentifiers)
    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
    private func uniformMimeType(for fileExtension: String) -> String? {
        UTType(filenameExtension: fileExtension)?.preferredMIMEType
    }
    #endif

    #if canImport(CoreServices)
    private func coreServicesMimeType(for fileExtension: String) -> String? {
        if
            let id = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension as CFString, nil)?.takeRetainedValue(),
            let contentType = UTTypeCopyPreferredTagWithClass(id, kUTTagClassMIMEType)?.takeRetainedValue()
        {
            return contentType as String
        }
        return nil
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
