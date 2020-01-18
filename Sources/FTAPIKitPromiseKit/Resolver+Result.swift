import PromiseKit

extension Resolver {
    func resolve<E: Error>(result: Swift.Result<T, E>) {
        switch result {
        case .success(let value):
            fulfill(value)
        case .failure(let error):
            reject(error)
        }
    }
}
