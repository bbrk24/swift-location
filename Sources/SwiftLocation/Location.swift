#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

public struct Location: Sendable {
    /// Latitude, in degrees.
    ///
    /// This is in the range \[-90, 90].
    public var latitude: Float
    
    /// Longitude, in degrees.
    ///
    /// This is in the range (-180, 180].
    public var longitude: Float
    
    /// Accuracy of latitude & longitude, in meters.
    ///
    /// This is the 68% confidence interval.
    public var horizontalAccuracy: Float
    
    /// The time at which the location was captured.
    public var timestamp: Date
    
    /// Altitude above mean sea level, in meters.
    public var altitude: Float?
    
    /// Accuracy of altitude, in meters.
    ///
    /// This is the 68% confidence interval.
    public var altitudeAccuracy: Float?
    
    /// Heading, in degrees from true north.
    ///
    /// This is in the range [0, 360).
    public var heading: Float?
    
    /// Accuracy of heading, in degrees.
    ///
    /// When present, this is the 68% confidence interval. This value is always `nil` on Windows.
    public var headingAccuracy: Float?
    
    /// Speed, in meters per second.
    public var speed: Float?
    
    /// Accuracy of speed, in meters per second.
    ///
    /// When present, this is the 68% confidence interval. This value is always `nil` on Windows.
    public var speedAccuracy: Float?
    
    public init(
        latitude: Float,
        longitude: Float,
        horizontalAccuracy: Float,
        timestamp: Date,
        altitude: Float? = nil,
        altitudeAccuracy: Float? = nil,
        heading: Float? = nil,
        headingAccuracy: Float? = nil,
        speed: Float? = nil,
        speedAccuracy: Float? = nil
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.horizontalAccuracy = horizontalAccuracy
        self.timestamp = timestamp
        self.altitude = altitude
        self.altitudeAccuracy = altitudeAccuracy
        self.heading = heading
        self.headingAccuracy = headingAccuracy
        self.speed = speed
        self.speedAccuracy = speedAccuracy
    }
}
