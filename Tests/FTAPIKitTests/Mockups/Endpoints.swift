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

    let parameters: User
    let path = "anything"

    struct Wrapper: Decodable {
        let json: User
    }
}

struct FailingUpdateUserEndpoint: RequestResponseEndpoint {
    typealias Response = User

    let parameters: User
    let path = "anything"
}