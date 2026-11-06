struct UnsupportedLocationManager: LocationManager {
    typealias LocationSequence = AlwaysThrowingAsyncSequence<Location, LocationError>

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

    func observeLocation(
        accuracy: LocationAccuracy,
        minMovement: Float,
        minPeriod: Float
    ) -> AlwaysThrowingAsyncSequence<Location, LocationError> {
        return AlwaysThrowingAsyncSequence {
            do {
                try Task.checkCancellation()
            } catch {
                return LocationError.cancelled(error as! CancellationError)
            }

            return LocationError.locationUnavailable
        }
    }
}
