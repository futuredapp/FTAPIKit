// swiftlint:disable nesting
import Foundation
#if canImport(Combine)
import Combine

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
extension Publishers {
    struct Endpoint<R, E: Error>: Publisher {
        typealias Output = R
        typealias Failure = E

        typealias Builder = (@escaping (Result<R, E>) -> Void) -> URLSessionTask?

        let builder: Builder

        func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
            let subscription = EndpointSubscription(subscriber: subscriber, builder: builder)
            subscriber.receive(subscription: subscription)
        }
    }
}

#endif
