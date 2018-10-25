//
//  URLRequest+APIAdapter.swift
//  FuntastyKit
//
//  Created by Matěj Kašpar Jirásek on 02/09/2018.
//  Copyright © 2018 FUNTASTY Digital s.r.o. All rights reserved.
//

import Foundation

extension URLRequest {
    mutating func setRequestType(_ requestType: RequestType, parameters: HTTPParameters, using jsonEncoder: JSONEncoder) throws {
        switch requestType {
        case .jsonBody(let encodable):
            try setJSONBody(encodable: encodable, parameters: parameters, using: jsonEncoder)
        case .urlEncoded:
            setURLEncoded(parameters: parameters)
        case .jsonParams:
            setJSON(parameters: parameters, using: jsonEncoder)
        case let .multipart(files):
            setMultipart(parameters: parameters, files: files)
        case .base64Upload:
            appendBase64(parameters: parameters)
        case .urlQuery:
            url?.appendQuery(parameters: parameters)
        }
    }

    mutating func appendBase64(parameters: HTTPParameters) {
        var urlComponents = URLComponents()
        urlComponents.queryItems = parameters.map(URLQueryItem.init)
        httpBody = urlComponents.query?.data(using: String.Encoding.ascii, allowLossyConversion: true)
        setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    }

    mutating func setMultipart(parameters: HTTPParameters = [:], files: [MultipartFile] = [], boundary: String = "APIAdapter" + UUID().uuidString) {
        setValue("multipart/form-data; charset=utf-8; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        for parameter in parameters {
            appendForm(data: Data(parameter.value.utf8), name: parameter.key, boundary: boundary)
        }
        for file in files {
            appendForm(data: file.data, name: file.name, boundary: boundary, mimeType: file.mimeType, filename: file.filename)
        }
        httpBody?.appendRow("--\(boundary)")
    }

    mutating func setJSON(parameters: HTTPParameters, body: Data? = nil, using jsonEncoder: JSONEncoder) {
        setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        httpBody = body
        url?.appendQuery(parameters: parameters)
    }

    mutating func setURLEncoded(parameters: HTTPParameters) {
        var urlComponents = URLComponents()
        urlComponents.queryItems = parameters.map(URLQueryItem.init)
        httpBody = urlComponents.query?.data(using: .ascii, allowLossyConversion: true)
        setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    }

    mutating func setJSONBody(encodable: Encodable, parameters: HTTPParameters, using jsonEncoder: JSONEncoder) throws {
        let body = try jsonEncoder.encode(AnyEncodable(encodable))
        setJSON(parameters: parameters, body: body, using: jsonEncoder)
    }

    private mutating func appendForm(data: Data, name: String, boundary: String, mimeType: String? = nil, filename: String? = nil) {
        if httpBody == nil {
            httpBody = Data(capacity: data.count)
        }
        httpBody?.appendRow("--\(boundary)")

        httpBody?.append("Content-Disposition: form-data; name=\(name)")
        if let filename = filename {
            httpBody?.append("; filename=\"\(filename)\"")
        }
        httpBody?.appendRow()
        if let mimeType = mimeType {
            httpBody?.appendRow("Content-Type: \(mimeType)")
        }
        httpBody?.appendRow()

        httpBody?.append(data)
        httpBody?.appendRow()
    }
}
