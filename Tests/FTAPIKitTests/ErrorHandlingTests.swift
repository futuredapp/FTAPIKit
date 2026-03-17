import Foundation
import FTAPIKit
import Testing

/// Tests for error handling, ported from the deleted ResponseTests.swift
@Suite
struct ErrorHandlingTests {

    @Test
    func clientError() async throws {
        let server = HTTPBinServer()
        let endpoint = NotFoundEndpoint()
        do {
            _ = try await server.call(data: endpoint)
            Issue.record("Expected client error for 404")
        } catch let error as APIError.Standard {
            guard case .client(let statusCode, _, _) = error else {
                Issue.record("Expected .client error, got \(error)")
                return
            }
            #expect(statusCode == 404)
        } catch {
            Issue.record("Unexpected error type: \(type(of: error))")
        }
    }

    @Test
    func serverError() async throws {
        let server = HTTPBinServer()
        let endpoint = ServerErrorEndpoint()
        do {
            _ = try await server.call(data: endpoint)
            Issue.record("Expected server error for 500")
        } catch let error as APIError.Standard {
            guard case .server(let statusCode, _, _) = error else {
                Issue.record("Expected .server error, got \(error)")
                return
            }
            #expect(statusCode == 500)
        } catch {
            Issue.record("Unexpected error type: \(type(of: error))")
        }
    }

    @Test
    func connectionError() async throws {
        let server = NonExistingServer()
        let endpoint = GetEndpoint()
        do {
            _ = try await server.call(data: endpoint)
            Issue.record("Expected connection error")
        } catch let error as APIError.Standard {
            guard case .connection = error else {
                Issue.record("Expected .connection error, got \(error)")
                return
            }
        } catch {
            Issue.record("Unexpected error type: \(type(of: error))")
        }
    }

    @Test
    func decodingError() async throws {
        let server = HTTPBinServer()
        let user = User(uuid: UUID(), name: "Test", age: 25)
        let endpoint = FailingUpdateUserEndpoint(request: user)
        do {
            _ = try await server.call(response: endpoint)
            Issue.record("Expected decoding error")
        } catch let error as APIError.Standard {
            guard case .decoding = error else {
                Issue.record("Expected .decoding error, got \(error)")
                return
            }
        } catch {
            Issue.record("Unexpected error type: \(type(of: error))")
        }
    }

    @Test
    func customErrorType() async throws {
        let server = ErrorThrowingServer()
        let endpoint = NotFoundEndpoint()
        do {
            _ = try await server.call(data: endpoint)
            Issue.record("Expected ThrowawayAPIError")
        } catch is ThrowawayAPIError {
            // Expected
        } catch {
            Issue.record("Unexpected error type: \(type(of: error))")
        }
    }

    @Test
    func emptyResponse() async throws {
        let server = HTTPBinServer()
        let endpoint = NoContentEndpoint()
        try await server.call(endpoint: endpoint)
    }

    @Test
    func authorization() async throws {
        let server = HTTPBinServer()
        let endpoint = AuthorizedEndpoint()
        let data = try await server.call(data: endpoint, configuring: BearerTokenConfiguration())
        #expect(!data.isEmpty)
    }
}
