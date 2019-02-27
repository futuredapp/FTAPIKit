//
//  Data+APIAdapter.swift
//  FTAPIKit-iOS
//
//  Created by Matěj Kašpar Jirásek on 03/09/2018.
//  Copyright © 2018 FUNTASTY Digital s.r.o. All rights reserved.
//

import Foundation

#if os(iOS) || os(watchOS) || os(tvOS)
import MobileCoreServices
#elseif os(macOS)
import CoreServices
#endif

extension URL {
    mutating func appendQuery(parameters: [String: String]) {
        self = appendingQuery(parameters: parameters)
    }

    func appendingQuery(parameters: [String: String]) -> URL {
        guard !parameters.isEmpty else {
            return self
        }
        var components = URLComponents(url: self, resolvingAgainstBaseURL: true)
        let oldItems = components?.queryItems ?? []
        components?.queryItems = oldItems + parameters.map(URLQueryItem.init)
        return components?.url ?? self
    }

    var mimeType: String {
        if let id = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as CFString, nil)?.takeRetainedValue(), let contentType = UTTypeCopyPreferredTagWithClass(id, kUTTagClassMIMEType)?.takeRetainedValue() {
            return contentType as String
        }
        return "application/octet-stream"
    }

    func contentLength() throws -> Int64 {
        let attributes = try FileManager.default.attributesOfItem(atPath: path)
        guard let size = attributes[FileAttributeKey.size] as? Int64 else {
            throw APIError.uploadFileNotLoaded
        }
        return size
    }
}
