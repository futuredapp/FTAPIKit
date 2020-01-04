//
//  URLRequest+Endpoint.swift
//  FTAPIKit
//
//  Created by Matěj Kašpar Jirásek on 02/09/2018.
//  Copyright © 2018 FUNTASTY Digital s.r.o. All rights reserved.
//

import Foundation

extension URLRequest {
    mutating func setRequestType(_ requestType: RequestType, parameters: HTTPParameters, using encoding: Encoding) throws {
        switch requestType {
        case .jsonBody(let encodable):
            try setJSONBody(encodable: encodable, parameters: parameters, using: encoding)
        case .urlEncoded:
            setURLEncoded(parameters: parameters)
        case .jsonParams:
            setJSON(parameters: parameters, using: encoding)
        case let .multipart(files):
            try setMultipart(parameters: parameters, files: files)
        case .base64Upload:
            appendBase64(parameters: parameters)
        case .urlQuery:
            url?.appendQuery(parameters: parameters)
        }
    }

    private mutating func appendBase64(parameters: HTTPParameters) {
        var urlComponents = URLComponents()
        urlComponents.queryItems = parameters.map(URLQueryItem.init)
        httpBody = urlComponents.query?.data(using: String.Encoding.ascii, allowLossyConversion: true)
        setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    }

    private mutating func setMultipart(parameters: HTTPParameters = [:], files: [MultipartBodyPart] = [], boundary: String = "FTAPIKit-" + UUID().uuidString) throws {

        let parameterParts = parameters.map(MultipartBodyPart.init)
        let multipartData = MultipartFormData(parts: parameterParts + files, boundary: "--" + boundary)

        httpBodyStream = try multipartData.inputStream()

        setValue("multipart/form-data; charset=utf-8; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if let contentLength = multipartData.contentLength {
            setValue(contentLength.description, forHTTPHeaderField: "Content-Length")
        }
    }

    private mutating func setJSON(parameters: HTTPParameters, body: Data? = nil, using encoding: Encoding) {
        setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        httpBody = body
        url?.appendQuery(parameters: parameters)
    }

    private mutating func setURLEncoded(parameters: HTTPParameters) {
        var urlComponents = URLComponents()
        urlComponents.queryItems = parameters.map(URLQueryItem.init)
        httpBody = urlComponents.query?.data(using: .ascii, allowLossyConversion: true)
        setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    }

    private mutating func setJSONBody(encodable: Encodable, parameters: HTTPParameters, using encoding: Encoding) throws {
        let body = try encoding.encode(AnyEncodable(encodable))
        setJSON(parameters: parameters, body: body, using: encoding)
    }
}
