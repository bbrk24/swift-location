#if canImport(CoreLocation)
import CoreLocation

final class CoreLocationManager: NSObject {
    private let clManager: CLLocationManager
    private var permissionContinuation: CheckedContinuation<Void, Never>?
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?

    override init() {
        clManager = CLLocationManager()
        permissionContinuation = nil
        locationContinuation = nil
        super.init()
        clManager.delegate = self
    }
}

extension CoreLocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        permissionContinuation?.resume()
        permissionContinuation = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        locationContinuation?.resume(throwing: error)
        locationContinuation = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            locationContinuation?.resume(returning: location)
            locationContinuation = nil
        }
    }
}

extension CoreLocationManager: LocationManager {
    typealias LocationSequence = AsyncThrowingStream<Location, LocationError>
    
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
    
    func requestPermission(_ permissions: LocationPermissions) async -> LocationPermissions {
        // If the request*Authorization method being called doesn't or can't result in the
        // permission changing, the delegate method is never called, so the continuation would hang.
        if clManager.authorizationStatus == .notDetermined {
            await withCheckedContinuation { continuation in
                self.permissionContinuation = continuation
                
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
            let clLocation = try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { continuation in
                    locationContinuation = continuation
                    clManager.desiredAccuracy = accuracy.appleValue.rawValue
                    clManager.requestLocation()
                }
            } onCancel: {
                // TODO: This can't access locationContinuation because of sendability constraints,
                // and it can't throw the CancellationError directly either. Figure out what to do
                // here.
            }

            return Location(
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
        } catch let clError as CLError {
            throw CoreLocationManager.toLocationError(clError)
        } catch let error as CancellationError {
            clManager.stopUpdatingLocation()
            throw .cancelled(error)
        } catch let error {
            throw .other(String(describing: error))
        }
    }
    
    func observeLocation(
        accuracy: LocationAccuracy,
        minMovement: Float,
        minPeriod: Float
    ) async -> LocationSequence {
        fatalError("TODO")
    }
}
#endif
