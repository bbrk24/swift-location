public enum LocationError: Error, CustomDebugStringConvertible {
    /// The app does not have the requisite permission to make this request.
    case missingPermission
    /// The location fix took too long and the request timed out.
    case timeout
    /// Location services are not currently available.
    ///
    /// This could be a transient condition such as a network error, or that the device does not
    /// have location services.
    case locationUnavailable
    /// The requested accuracy could not be satisfied.
    case inaccurate
    /// The containing task was cancelled.
    case cancelled(CancellationError)
    /// An unexpected error occurred.
    case other(String)
    
    public var debugDescription: String {
        switch self {
        case .missingPermission:
            "The requisite permission has not been granted."
        case .timeout:
            "The location request timed out."
        case .locationUnavailable:
            "Location services are currently unavailable."
        case .inaccurate:
            "The specified accuracy could not be satisfied."
        case .cancelled(_):
            "The task was cancelled."
        case .other(let message):
            "An unexpected error occurred: " + message
        }
    }
}
