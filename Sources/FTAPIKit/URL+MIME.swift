import UniformTypeIdentifiers

extension URL {
    var mimeType: String {
        UTType(filenameExtension: pathExtension)?.preferredMIMEType ?? "application/octet-stream"
    }
}
