import Foundation
#if canImport(Combine)
import Combine
#endif

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
final class EndpointSubscription<S: Subscriber, R, E>: Subscription where S.Input == R, S.Failure == E {
    private let builder: Publishers.Endpoint<R, E>.Builder
    private var subscriber: S?

    private var task: URLSessionTask?

    init(subscriber: S, builder: @escaping Publishers.Endpoint<R, E>.Builder) {
        self.subscriber = subscriber
        self.builder = builder
    }

    func request(_ demand: Subscribers.Demand) {
        guard demand > .none, task == nil else {
            return
        }

        task = builder { [subscriber] result in
            switch result {
            case .success(let input):
                _ = subscriber?.receive(input)
            case .failure(let error):
                subscriber?.receive(completion: .failure(error))
            }
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
        subscriber = nil
    }
}
