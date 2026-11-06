struct TypedThrowsAsyncWrapper<
    Wrapped: AsyncSequence,
    Element: Sendable,
    Failure: Error
>: AsyncSequence
where Wrapped.Element == Result<Element, Failure>, Wrapped.Failure == Never {
    var wrapped: Wrapped
    var onCancel: @Sendable () -> Void
    
    init(
        wrapping wrapped: Wrapped,
        onCancel: @Sendable @escaping () -> Void = { }
    ) {
        self.wrapped = wrapped
        self.onCancel = onCancel
    }
    
    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(wrapped: wrapped.makeAsyncIterator(), onCancel: onCancel)
    }
    
    struct AsyncIterator: AsyncIteratorProtocol {
        var wrapped: Wrapped.AsyncIterator
        var onCancel: @Sendable () -> Void

        mutating func next(isolation actor: isolated (any Actor)?) async throws(Failure) -> Element? {
            let result = await withTaskCancellationHandler(operation: {
                await wrapped.next(isolation: actor)
            }, onCancel: onCancel)

            return try result?.get()
        }
    }
}

extension TypedThrowsAsyncWrapper: Sendable
where Wrapped: Sendable {}

extension TypedThrowsAsyncWrapper.AsyncIterator: Sendable
where Wrapped.AsyncIterator: Sendable {}
