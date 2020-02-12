# FTAPIKit

![Swift](https://github.com/futuredapp/FTAPIKit/workflows/Swift/badge.svg)
![Cocoapods](https://img.shields.io/cocoapods/v/FTAPIKit)
![Cocoapods platforms](https://img.shields.io/cocoapods/p/FTAPIKit)
![License](https://img.shields.io/cocoapods/l/FTAPIKit)

Declarative and generic REST API framework using Codable.
With standard implementation using URLSesssion and JSON encoder/decoder.
Easily extensible for your asynchronous framework or networking stack.

## Installation

When using Swift package manager install using Xcode 11+
or add following line to your dependencies:

```swift
.package(url: "https://github.com/futuredapp/FTAPIKit.git", from: "1.0.0")
```

When using CocoaPods add following line to your `Podfile`:

```ruby
pod 'FTAPIKit', '~> 1.0'
```

# Features

The main feature of this library is to provide documentation-like API
for defining web services. This is achieved using declarative
and protocol-oriented programming in Swift.

The framework provides two core protocols reflecting the physical infrastructure:

- `Server` protocol defining single web service.
- `Endpoint` protocol defining access points for resources.

Combining instances of type conforming to `Server` and `Endpoint` we can build request.
`URLServer` has convenience method for calling endpoints using `URLSession`.
Recommended usage on application-side is implementing API client which encapsulates
logic not provided by this framework like signing authorized endpoints
or conforming to `URLSessionDelegate`.

![Architecture](Documentation/Architecture.svg)

There are many convenient `Endpoint` protocols for various use cases
like multipart upload, automatic encoding/decoding.

- `Endpoint` protocol body is empty.
- `DataEndpoint` sends provided data in body.
- `UploadEndpoint` sends file in body stream.
- `MultipartEndpoint` combines body parts into body stream.
- `RequestEndpoint` has encodable request which is encoded using server encoding.

![Endpoint types](Documentation/Endpoints.svg)

## Usage

### Defining web service (server)

Firstly we need to define our server. We recommend using structs:

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
    var token: String?

    ...

    func buildRequest(endpoint: Endpoint) throws -> URLRequest {
        var request = try buildStandardRequest(endpoint: endpoint)
        if let token = token {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
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

As an example of a bit more complicated endpoint encoding encodable struct,
sending it to server and receiving updated value back from the server
we only need to define following code:

```swift
struct UpdateUserEndpoint: RequestResponseEndpoint {
    typealias Response = User

    let request: User
    let path = "user"
}
```

### Executing the request

When we have server and enpoint defined we can call the web service:

```swift
let server = HTTPBinServer()
let endpoint = UpdateUserEndpoint(request: user)
server.call(response: endpoint) { result in
    switch result {
    case .success(let updatedUser):
        ...
    case .failure(let error):
        ...
    }
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
