/// The main class for getting locations and checking permissions.
///
/// A location manager does not necessarily support requesting the location from multiple tasks at
/// once. If such a manager is called re-entrantly, it will throw ``LocationError/requestInFlight``.
public protocol LocationManager: Sendable {
    /// Whether the device currently has access to location features.
    var isLocationAvailable: Bool { get }
    
    /// Check whether the specified permissions have been granted.
    func hasPermission(_ permissions: LocationPermissions) -> LocationPermissionStatus
    
    /// Prompt the user for the specified permissions.
    ///
    /// - Returns: The permissions the user actually granted.
    @MainActor
    func requestPermission(_ permissions: LocationPermissions) async -> LocationPermissions
    
    /// Get the current location to within the specified accuracy.
    func getLocation(accuracy: LocationAccuracy) async throws(LocationError) -> Location

    associatedtype LocationSequence: AsyncSequence
    where LocationSequence.Element == Location, LocationSequence.Failure == LocationError

    /// Start listening for changes to the location.
    /// - Parameters:
    ///   - accuracy: How accurate each location needs to be
    ///   - minMovement: How much the user needs to move, in meters, before a new fix is generated
    ///   - minPeriod: How much time needs to pass, in seconds, before a new fix is generated
    func observeLocation(
        accuracy: LocationAccuracy,
        minMovement: Float,
        minPeriod: Float
    ) -> LocationSequence
}

extension LocationManager {
    public static func createInstance() -> any LocationManager {
        #if canImport(CoreLocation)
            return CoreLocationManager()
        #else
            return UnsupportedLocationManager()
        #endif
    }
}
