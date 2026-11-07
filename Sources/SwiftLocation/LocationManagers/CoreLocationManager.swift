#if canImport(CoreLocation)
import CoreLocation
import Synchronization

final class CoreLocationManager: NSObject, @unchecked Sendable {
    private let clManager: CLLocationManager
    private let permissionContinuation: Mutex<CheckedContinuation<Void, Never>?>
    private let locationContinuation: Mutex<Either<
        CheckedContinuation<CLLocation, Error>,
        AsyncStream<Result<Location, LocationError>>.Continuation
    >?>

    override init() {
        clManager = CLLocationManager()
        permissionContinuation = Mutex(nil)
        locationContinuation = Mutex(nil)
        super.init()
        clManager.delegate = self
    }
}

extension Location {
    public init(clLocation: CLLocation) {
        self.init(
            latitude: Float(clLocation.coordinate.latitude),
            longitude: Float(clLocation.coordinate.longitude),
            horizontalAccuracy: Float(clLocation.horizontalAccuracy),
            timestamp: clLocation.timestamp,
            altitude: clLocation.verticalAccuracy <= 0.0 ? nil : Float(clLocation.altitude),
            altitudeAccuracy: clLocation.verticalAccuracy <= 0.0 ? nil : Float(clLocation.verticalAccuracy),
            heading: clLocation.course < 0.0 ? nil : Float(clLocation.course),
            headingAccuracy: clLocation.courseAccuracy < 0.0 ? nil : Float(clLocation.courseAccuracy),
            speed: clLocation.speed < 0.0 ? nil : Float(clLocation.speed),
            speedAccuracy: clLocation.speedAccuracy < 0.0 ? nil : Float(clLocation.speedAccuracy)
        )
    }
}

extension CoreLocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        permissionContinuation.withLock {
            $0?.resume()
            $0 = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        locationContinuation.withLock {
            switch $0 {
            case .left(let continuation):
                continuation.resume(throwing: error)
            case .right(let continuation):
                if let clError = error as? CLError {
                    continuation.yield(.failure(CoreLocationManager.toLocationError(clError)))
                } else {
                    continuation.yield(.failure(.other(String(describing: error))))
                }
                continuation.finish()
            case nil:
                break
            }
            $0 = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationContinuation.withLock {
            switch $0 {
            case .left(let continuation):
                if let location = locations.last {
                    continuation.resume(returning: location)
                    $0 = nil
                }
            case .right(let continuation):
                for location in locations {
                    continuation.yield(.success(.init(clLocation: location)))
                }
            case nil:
                break
            }
        }
    }
}

extension CoreLocationManager: LocationManager {
    var isLocationAvailable: Bool { CLLocationManager.locationServicesEnabled() }
    
    func hasPermission(_ permissions: LocationPermissions) -> LocationPermissionStatus {
        if permissions == [] {
            return .granted
        }

        switch clManager.authorizationStatus {
        case .notDetermined:
            return .notPrompted
        #if !os(macOS)
        case .authorizedWhenInUse:
            if permissions == .background {
                return .denied
            }

            if clManager.accuracyAuthorization == .reducedAccuracy {
                if permissions == .coarse {
                    return .granted
                } else if permissions.contains(.coarse) {
                    return .partiallyGranted
                } else {
                    return .denied
                }
            }

            if permissions.contains(.background) {
                return .partiallyGranted
            } else {
                return .granted
            }
        #endif
        case .authorizedAlways:
            if clManager.accuracyAuthorization == .reducedAccuracy {
                if permissions == .fine {
                    return .denied
                } else if permissions.contains(.fine) {
                    return .partiallyGranted
                }
            }
            return .granted
        default:
            return .denied
        }
    }

    @MainActor
    func requestPermission(_ permissions: LocationPermissions) async -> LocationPermissions {
        // If the request*Authorization method being called doesn't or can't result in the
        // permission changing, the delegate method is never called, so the continuation would hang.
        #if os(macOS)
        let canPermissionChange = clManager.authorizationStatus == .notDetermined
        #else
        let canPermissionChange = clManager.authorizationStatus == .notDetermined
            || (permissions.contains(.background) && clManager.authorizationStatus == .authorizedWhenInUse)
        #endif
        if canPermissionChange {
            await withCheckedContinuation { continuation in
                permissionContinuation.withLock {
                    // Only assert instead of precondition because the CheckedContinuation itself will
                    // blow up if this fails. The assert here just provides a better message.
                    assert($0 == nil, "\(#function) called re-entrantly")

                    $0 = continuation
                }

                if permissions.contains(.background) {
                    clManager.requestAlwaysAuthorization()
                } else {
                    clManager.requestWhenInUseAuthorization()
                }
            }
        }

        switch clManager.authorizationStatus {
        #if !os(macOS)
        case .authorizedWhenInUse:
            switch clManager.accuracyAuthorization {
            case .fullAccuracy:
                return [.coarse, .fine]
            default:
                return .coarse
            }
        #endif
        case .authorizedAlways:
            switch clManager.accuracyAuthorization {
            case .fullAccuracy:
                return [.coarse, .fine, .background]
            default:
                return [.coarse, .background]
            }
        default:
            return []
        }
    }
    
    private static func toLocationError(_ clError: CLError) -> LocationError {
        switch clError.code {
        case .deferredFailed, .rangingUnavailable, .deferredNotUpdatingLocation, .network:
            .locationUnavailable
        case .denied, .regionMonitoringDenied, .promptDeclined:
            .missingPermission
        case .locationUnknown, .regionMonitoringSetupDelayed, .regionMonitoringResponseDelayed,
                .deferredCanceled:
            .timeout
        case .deferredAccuracyTooLow:
            .inaccurate
        default:
            .other(clError.localizedDescription)
        }
    }
    
    func getLocation(accuracy: LocationAccuracy) async throws(LocationError) -> Location {
        do {
            try Task.checkCancellation()

            let clLocation = try await withTaskCancellationHandler {
                return try await withCheckedThrowingContinuation { continuation in
                    locationContinuation.withLock {
                        if $0 == nil {
                            $0 = .left(continuation)
                            clManager.desiredAccuracy = accuracy.appleValue.rawValue
                            clManager.distanceFilter = kCLDistanceFilterNone
                            clManager.requestLocation()
                        } else {
                            continuation.resume(throwing: LocationError.requestInFlight)
                        }
                    }
                }
            } onCancel: {
                locationContinuation.withLock {
                    if case .left(let continuation) = $0 {
                        continuation.resume(throwing: CancellationError())
                        $0 = nil
                    }
                }
            }

            return Location(clLocation: clLocation)
        } catch let error as LocationError {
            throw error
        } catch let error as CLError {
            throw CoreLocationManager.toLocationError(error)
        } catch let error as CancellationError {
            clManager.stopUpdatingLocation()
            throw .cancelled(error)
        } catch let error {
            throw .other(String(describing: error))
        }
    }
    
    typealias LocationSequence = TypedThrowsAsyncWrapper<
        AsyncStream<Result<Location, LocationError>>,
        Location,
        LocationError
    >
    
    func observeLocation(
        accuracy: LocationAccuracy,
        minMovement: Float,
        minPeriod: Float
    ) -> LocationSequence {
        let stream = locationContinuation.withLock {
            var stream: AsyncStream<Result<Location, LocationError>>
            if $0 != nil {
                stream = AsyncStream { .failure(.requestInFlight) }
            } else {
                clManager.desiredAccuracy = accuracy.appleValue.rawValue
                clManager.distanceFilter = Double(minMovement)
                
                var continuation: AsyncStream<Result<Location, LocationError>>.Continuation
                (stream, continuation) = AsyncStream.makeStream(bufferingPolicy: .unbounded)
                $0 = .right(continuation)
                
                clManager.startUpdatingLocation()
            }
            
            return stream
        }

        return TypedThrowsAsyncWrapper(wrapping: stream) { [self] in
            clManager.stopUpdatingLocation()
            locationContinuation.withLock {
                if case .right(let continuation) = $0 {
                    continuation.yield(.failure(.cancelled(CancellationError())))
                    continuation.finish()
                    $0 = nil
                }
            }
        }
    }
}
#endif
