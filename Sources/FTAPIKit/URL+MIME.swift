import Foundation

#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
private func getUTMimeType(_ ext: String) -> String? {
    UTType(filenameExtension: ext)?.preferredMIMEType
}
#endif

#if canImport(CoreServices)
import CoreServices

private func getCSMimeType(_ ext: String) -> String? {
    if
        let id = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, ext as CFString, nil)?.takeRetainedValue(),
        let contentType = UTTypeCopyPreferredTagWithClass(id, kUTTagClassMIMEType)?.takeRetainedValue()
    {
        return contentType as String
    }

    return nil
}
#endif

#if os(Linux)
private func getLinuxMimeType(_ path: String) -> String? {
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

extension URL {
    var mimeType: String {
        let fallback = "application/octet-stream"

        #if os(Linux)
        return getLinuxMimeType(path) ?? fallback
        #else
        if #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *) {
            return getUTMimeType(pathExtension) ?? fallback
        } else {
            return getCSMimeType(pathExtension) ?? fallback
        }
        #endif
    }
}
