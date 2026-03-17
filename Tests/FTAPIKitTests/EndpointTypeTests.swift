import Foundation
import Testing

@testable import FTAPIKit

/// Tests for various endpoint types, ported from the deleted ResponseTests.swift
@Suite
struct EndpointTypeTests {

    @Test
    func responseEndpoint() async throws {
        let server = HTTPBinServer()
        let response = try await server.call(response: JSONResponseEndpoint())
        #expect(!response.slideshow.title.isEmpty)
    }

    @Test
    func requestResponseEndpoint() async throws {
        let server = HTTPBinServer()
        let user = User(uuid: UUID(), name: "Test User", age: 30)
        let endpoint = UpdateUserEndpoint(request: user)
        let response = try await server.call(response: endpoint)
        #expect(response.json == user)
    }

    @Test
    func urlEncodedEndpoint() async throws {
        let server = HTTPBinServer()
        let endpoint = TestURLEncodedEndpoint()
        let data = try await server.call(data: endpoint)
        #expect(!data.isEmpty)
    }

    @Test
    func multipartEndpoint() async throws {
        let server = HTTPBinServer()
        let file = File()
        try file.write()
        let endpoint = try TestMultipartEndpoint(file: file)
        let data = try await server.call(data: endpoint)
        #expect(!data.isEmpty)
    }

    @Test
    func uploadEndpoint() async throws {
        let server = HTTPBinServer()
        let file = File()
        try file.write()
        let endpoint = TestUploadEndpoint(file: file)
        let data = try await server.call(data: endpoint)
        #expect(!data.isEmpty)
    }

    @Test
    func downloadEndpoint() async throws {
        let server = HTTPBinServer()
        let endpoint = ImageEndpoint()
        let url = try await server.download(endpoint: endpoint)
        #expect(FileManager.default.fileExists(atPath: url.path))
    }
}
