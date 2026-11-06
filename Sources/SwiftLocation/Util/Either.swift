enum Either<T, U> {
    case left(T)
    case right(U)
}

extension Either: Sendable
where T: Sendable, U: Sendable {}
