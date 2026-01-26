<img align="right" alt="FTAPIKit logo" src="Sources/FTAPIKit/Documentation.docc/Resources/FTAPIKit.svg">

# FTAPIKit

![Cocoapods](https://img.shields.io/cocoapods/v/FTAPIKit)
![Cocoapods platforms](https://img.shields.io/cocoapods/p/FTAPIKit)
![License](https://img.shields.io/cocoapods/l/FTAPIKit)

![macOS 14](https://github.com/futuredapp/FTAPIKit/actions/workflows/macos-14.yml/badge.svg?branch=main)
![Ubuntu](https://github.com/futuredapp/FTAPIKit/actions/workflows/ubuntu-latest.yml/badge.svg?branch=main)

Declarative async/await REST API framework using Swift Concurrency and Codable.
With standard implementation using URLSession and JSON encoder/decoder.
Built for Swift 6.1 with full concurrency safety.

## Requirements

- Swift 6.1+
- iOS 15+, macOS 12+, tvOS 15+, watchOS 8+, or Linux

## Installation

When using Swift Package Manager install using Xcode or add the following line to your dependencies:

```swift
.package(url: "https://github.com/futuredapp/FTAPIKit.git", from: "2.0.0")
```

When using CocoaPods add following line to your `Podfile`:

```ruby
pod 'FTAPIKit', '~> 2.0'
```

## Features

The main feature of this library is to provide documentation-like API
for defining web services. This is achieved using declarative
and protocol-oriented programming in Swift.

The framework provides two core protocols reflecting the physical infrastructure:

- `Server` protocol defining single web service.
- `Endpoint` protocol defining access points for resources.

Combining instances of type conforming to `Server` and `Endpoint` we can build request.
`URLServer` has convenience method for calling endpoints using `URLSession`.
If some advanced features are required then we recommend implementing API client.
This client should encapsulate logic which is not provided by this framework
(like signing authorized endpoints or conforming to `URLSessionDelegate`).

![Architecture](Sources/FTAPIKit/Documentation.docc/Resources/Architecture.png)

This package contains predefined `Endpoint` protocols.
Use cases like multipart upload, automatic encoding/decoding
are separated in various protocols for convenience.

- `Endpoint` protocol has empty body. Typically used in `GET` endpoints.
- `DataEndpoint` sends provided data in body.
- `UploadEndpoint` uploads file using `InputStream`.
- `MultipartEndpoint` combines body parts into `InputStream` and sends them to server.
  Body parts are represented by `MultipartBodyPart` struct and provided to the endpoint
  in an array.
- `RequestEndpoint` has encodable request which is encoded using encoding
  of the `Server` instance.

![Endpoint types](Sources/FTAPIKit/Documentation.docc/Resources/Endpoints.svg)

## Usage

### Defining web service (server)

Firstly we need to define our server. Structs are preferred but not required:

```swift
struct HTTPBinServer: URLServer {
    let baseUri = URL(string: "http://httpbin.org/")!
    let urlSession = URLSession(configuration: .default)
}
```

If we want to use custom formatting we just need to add our encoding/decoding configuration:

```swift
struct HTTPBinServer: URLServer {
    ...

    let decoding: Decoding = JSONDecoding { decoder in
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    let encoding: Encoding = JSONEncoding { encoder in
        encoder.keyEncodingStrategy = .convertToSnakeCase
    }
}
```

If we need to create specific request, add some headers, usually to provide
authorization we can override default request building mechanism.

```swift
struct HTTPBinServer: URLServer {
    ...
    func buildRequest(endpoint: Endpoint) async throws -> URLRequest {
        var request = try buildStandardRequest(endpoint: endpoint)
        request.addValue("MyApp/1.0.0", forHTTPHeaderField: "User-Agent")
        return request
    }
}
```

### Defining endpoints

Most basic `GET` endpoint can be implemented using `Endpoint` protocol,
all default propertires are inferred.

```swift
struct GetEndpoint: Endpoint {
    let path = "get"
}
```

Let's take more complicated example like updating some model.
We need to supply encodable request and decodable response.

```swift
struct UpdateUserEndpoint: RequestResponseEndpoint {
    typealias Response = User

    let request: User
    let path = "user"
}
```

### Executing the request

When we have server and endpoint defined we can call the web service using async/await:

```swift
let server = HTTPBinServer()
let endpoint = UpdateUserEndpoint(request: user)

Task {
    do {
        let updatedUser = try await server.call(response: endpoint)
        // Handle success
    } catch {
        // Handle error
    }
}
```

### Async buildRequest

One of the key features in FTAPIKit 2.0 is the ability to use async operations in `buildRequest`. This enables use cases like:

- **Token Refresh**: Await token refresh before building the request
- **Dynamic Configuration**: Fetch configuration or headers asynchronously
- **Rate Limiting**: Implement delays or throttling

Example with async token refresh:

```swift
struct MyServer: URLServer {
    let baseUri = URL(string: "https://api.example.com")!
    let tokenManager: TokenManager

    func buildRequest(endpoint: Endpoint) async throws -> URLRequest {
        // Refresh token if needed
        await tokenManager.refreshIfNeeded()

        var request = try buildStandardRequest(endpoint: endpoint)
        request.addValue("Bearer \(tokenManager.token)", forHTTPHeaderField: "Authorization")
        return request
    }
}
```

### Request Configuration at Call Site

For scenarios where you need to configure requests at the call site (rather than in the server),
use the `RequestConfiguring` protocol. This is useful for:

- Adding authorization headers in an API service layer
- Per-request configuration that varies by context
- Keeping server implementations simple and reusable

```swift
struct AuthorizedConfiguration: RequestConfiguring {
    let authService: AuthService

    func configure(_ request: inout URLRequest) async throws {
        let token = try await authService.getValidAccessToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
}

// Usage - configuration is optional with nil default
let server = HTTPBinServer()
let authConfig = AuthorizedConfiguration(authService: authService)

// Public endpoint - no configuration needed
let publicData = try await server.call(response: publicEndpoint)

// Protected endpoint - with configuration
let protectedData = try await server.call(response: protectedEndpoint, configuring: authConfig)
```

This pattern keeps the server layer focused on request building while allowing
the API service layer to handle authentication concerns.

## Migrating from 1.x to 2.0

FTAPIKit 2.0 is a major rewrite focused on Swift Concurrency. Here are the breaking changes:

### Completion Handlers Removed

**Old (1.x):**
```swift
server.call(response: endpoint) { result in
    switch result {
    case .success(let response):
        print(response)
    case .failure(let error):
        print(error)
    }
}
```

**New (2.0):**
```swift
Task {
    do {
        let response = try await server.call(response: endpoint)
        print(response)
    } catch {
        print(error)
    }
}
```

### Combine Removed

Combine support has been removed in favor of async/await, which provides better performance and cleaner code.

**Old (1.x) - Combine:**
```swift
server.publisher(response: endpoint)
    .sink(
        receiveCompletion: { completion in
            // Handle completion
        },
        receiveValue: { response in
            // Handle response
        }
    )
    .store(in: &cancellables)
```

**New (2.0) - Async/Await:**
```swift
let task = Task {
    do {
        let response = try await server.call(response: endpoint)
        // Handle response
    } catch {
        // Handle error
    }
}

// Cancel if needed
task.cancel()
```

### buildRequest is Now Async

If you override `buildRequest`, you must mark it as `async`:

**Old (1.x):**
```swift
func buildRequest(endpoint: Endpoint) throws -> URLRequest {
    var request = try buildStandardRequest(endpoint: endpoint)
    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    return request
}
```

**New (2.0):**
```swift
func buildRequest(endpoint: Endpoint) async throws -> URLRequest {
    var request = try buildStandardRequest(endpoint: endpoint)
    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    return request
}
```

### Response Types Must Be Sendable

All `ResponseEndpoint` response types must conform to `Sendable` for Swift 6 concurrency safety:

```swift
struct User: Codable, Sendable {  // Add Sendable conformance
    let id: Int
    let name: String
}
```

## Contributors

Current maintainer and main contributor is [Matěj Kašpar Jirásek](https://github.com/mkj-is), <matej.jirasek@futured.app>.

We want to thank other contributors, namely:

- [Mikoláš Stuchlík](https://github.com/mikolasstuchlik)
- [Radek Doležal](https://github.com/eRDe33)
- [Adam Bezák](https://github.com/bezoadam)
- [Patrik Potoček](https://github.com/Patrez)

## License

FTAPIKit is available under the MIT license. See the [LICENSE file](LICENSE) for more information.
