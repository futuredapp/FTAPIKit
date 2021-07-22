//import CoreServices
import Foundation

extension URL {
    var mimeType: String {
        // if let id = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as CFString, nil)?.takeRetainedValue(), let contentType = UTTypeCopyPreferredTagWithClass(id, kUTTagClassMIMEType)?.takeRetainedValue() {
        //     return contentType as String
        // }
        return "application/octet-stream"
    }
}
