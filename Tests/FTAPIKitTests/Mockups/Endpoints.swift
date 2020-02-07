import FTAPIKit
import Foundation

struct GetEndpoint: Endpoint {
    let path = "get"
}

struct NoContentEndpoint: Endpoint {
    let path = "status/204"
}

struct NotFoundEndpoint: Endpoint {
    let path = "status/404"
}

struct AuthorizedEndpoint: Endpoint {
    let path = "bearer"
}

struct ServerErrorEndpoint: Endpoint {
    let path = "status/500"
}

struct JSONResponseEndpoint: ResponseEndpoint {
    typealias Response = TopLevel

    let path = "json"

    struct TopLevel: Decodable {
        let slideshow: Slideshow
    }

    struct Slideshow: Decodable {
        let author, date: String
        let slides: [Slide]
        let title: String
    }

    struct Slide: Decodable {
        let title, type: String
        let items: [String]?
    }
}

struct UpdateUserEndpoint: RequestResponseEndpoint {
    typealias Response = Wrapper

    let request: User
    let path = "anything"

    struct Wrapper: Decodable {
        let json: User
    }
}

struct FailingUpdateUserEndpoint: RequestResponseEndpoint {
    typealias Response = User

    let request: User
    let path = "anything"
}

struct TestMultipartEndpoint: MultipartEndpoint {
    let parts: [MultipartBodyPart]
    let path = "post"
    let method: HTTPMethod = .post

    init(file: File) throws {
        self.parts = [
            MultipartBodyPart(name: "anotherParameter", value: "valueForParameter"),
            try MultipartBodyPart(name: "urlImage", url: file.url),
            MultipartBodyPart(headers: file.headers, data: file.data),
            MultipartBodyPart(headers: file.headers, inputStream: InputStream(url: file.url) ?? InputStream())
        ]
    }
}

struct TestURLEncodedEndpoint: URLEncodedEndpoint {
    let path = "post"
    let method: HTTPMethod = .post
    let body: [String: String] = [
        "param1": "value1",
        "param2": "value2",
    ]
}

struct TestUploadEndpoint: UploadEndpoint {
    let file: URL
    let path = "put"
    let method: HTTPMethod = .put

    init(file: File) {
        self.file = file.url
    }
}

struct ImageEndpoint: Endpoint {
    let path = "image/jpeg"
}
