import Foundation

#if canImport(CoreServices)
import CoreFoundation
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
        process.arguments = ["file", "--brief", "--mime-type", absoluteString]
        process.standardOutput = pipe
        do {
            try process.run()
        } catch {
            assertionFailure("File mime could not be determined: \(error)")
        }

        return String(
            data: stdOut.fileHandleForReading.readDataToEndOfFile(), 
            encoding: .utf8
        )?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
#endif

}
