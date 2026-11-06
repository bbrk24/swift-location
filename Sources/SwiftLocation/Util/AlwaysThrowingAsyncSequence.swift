struct AlwaysThrowingAsyncSequence<T: Sendable, Failure: Error>: AsyncSequence, AsyncIteratorProtocol, Sendable {
    var generateError: @Sendable () -> Failure

    func next(isolation actor: isolated (any Actor)?) async throws(Failure) -> T? {
        throw generateError()
    }
    
    func makeAsyncIterator() -> AlwaysThrowingAsyncSequence<T, Failure> {
        self
    }
}
