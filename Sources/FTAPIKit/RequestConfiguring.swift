import Foundation

/// Protocol for configuring URLRequest before execution.
/// Implementations can perform async operations like token refresh.
///
/// Use this protocol to add authorization headers, modify requests, or perform
/// any async configuration needed before the request is sent.
///
/// Example:
/// ```swift
/// struct AuthorizedConfiguration: RequestConfiguring {
///     let authService: AuthService
///
///     func configure(_ request: inout URLRequest) async throws {
///         let token = try await authService.getValidAccessToken()
///         request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
///     }
/// }
/// ```
public protocol RequestConfiguring: Sendable {
    /// Configures the request before it is sent.
    /// - Parameter request: The URLRequest to configure
    /// - Throws: Any error that occurs during configuration (e.g., token refresh failure)
    func configure(_ request: inout URLRequest) async throws
}

/// Composes multiple ``RequestConfiguring`` instances into a single configuration.
///
/// Configurations are applied in order, so later configurations can override
/// headers set by earlier ones.
///
/// ```swift
/// let config = CompositeRequestConfiguring([authConfig, tracingConfig])
/// let data = try await server.call(data: endpoint, configuring: config)
/// ```
public struct CompositeRequestConfiguring: RequestConfiguring {
    private let configurations: [any RequestConfiguring]

    /// Creates a composite configuration from multiple configurations.
    /// - Parameter configurations: Configurations to apply in order.
    public init(_ configurations: [any RequestConfiguring]) {
        self.configurations = configurations
    }

    public func configure(_ request: inout URLRequest) async throws {
        for configuration in configurations {
            try await configuration.configure(&request)
        }
    }
}
