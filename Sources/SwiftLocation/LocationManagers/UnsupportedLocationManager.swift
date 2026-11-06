struct UnsupportedLocationManager: LocationManager {
    typealias LocationSequence = AsyncThrowingStream<Location, LocationError>
    
    var isLocationAvailable: Bool { false }
    
    func hasPermission(_ permissions: LocationPermissions) -> LocationPermissionStatus {
        .denied
    }
    
    func requestPermission(_ permissions: LocationPermissions) async -> LocationPermissions {
        []
    }
    
    func getLocation(accuracy: LocationAccuracy) async throws(LocationError) -> Location {
        throw .locationUnavailable
    }

    func observeLocation(accuracy: LocationAccuracy, minMovement: Float, minPeriod: Float) async -> AsyncThrowingStream<Location, LocationError> {
        // FIXME: https://forums.swift.org/t/creating-a-typed-throws-asyncsequence/90520
        // return AsyncThrowingStream { throw LocationError.locationUnavailable }
        fatalError("TODO")
    }
}
