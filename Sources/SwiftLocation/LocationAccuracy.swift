public struct WindowsLocationAccuracy: RawRepresentable<UInt32>, Sendable, Hashable, BitwiseCopyable {
    /// The desired accuracy, in meters.
    public var rawValue: UInt32
    
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
    
    public static let `default` = WindowsLocationAccuracy(rawValue: 500)
    public static let high = WindowsLocationAccuracy(rawValue: 10)
}

public enum AndroidLocationAccuracy: Int32, Sendable, BitwiseCopyable {
    /// Provide very accurate locations at the expense of potentially increased power usage.
    ///
    /// https://developer.android.com/reference/android/location/LocationRequest#QUALITY_HIGH_ACCURACY
    case high = 100
    /// Equally balance power and accuracy constraints.
    ///
    /// https://developer.android.com/reference/android/location/LocationRequest#QUALITY_BALANCED_POWER_ACCURACY
    case balanced = 102
    /// Provide less accurate locations in order to save power.
    ///
    /// https://developer.android.com/reference/android/location/LocationRequest#QUALITY_LOW_POWER
    case low = 104
}

public enum AppleLocationAccuracy: Double, Sendable, BitwiseCopyable {
    /// The highest possible accuracy that uses additional sensor data to facilitate navigation apps.
    ///
    /// https://developer.apple.com/documentation/corelocation/kcllocationaccuracybestfornavigation
    case bestForNavigation = -2.0
    /// The best level of accuracy available.
    ///
    /// https://developer.apple.com/documentation/corelocation/kcllocationaccuracybest
    case best = -1.0
    /// Accurate to within ten meters of the desired target.
    ///
    /// https://developer.apple.com/documentation/corelocation/kcllocationaccuracynearesttenmeters
    case nearestTenMeters = 10.0
    /// Accurate to within one hundred meters.
    ///
    /// https://developer.apple.com/documentation/corelocation/kcllocationaccuracyhundredmeters
    case hundredMeters = 100.0
    /// Accurate to the nearest kilometer.
    ///
    /// https://developer.apple.com/documentation/corelocation/kcllocationaccuracykilometer
    case kilometer = 1000.0
    /// Accurate to the nearest three kilometers.
    ///
    /// https://developer.apple.com/documentation/corelocation/kcllocationaccuracythreekilometers
    case threeKilometers = 3000.0
    /// The level of accuracy used when an app isn’t authorized for full accuracy location data.
    ///
    /// https://developer.apple.com/documentation/corelocation/kcllocationaccuracyreduced
    case reduced = 6_380_000.0
}

public struct LocationAccuracy: Sendable {
    public var windowsValue: WindowsLocationAccuracy
    public var androidValue: AndroidLocationAccuracy
    public var appleValue: AppleLocationAccuracy

    public init(
        windowsValue: WindowsLocationAccuracy = .default,
        androidValue: AndroidLocationAccuracy = .balanced,
        appleValue: AppleLocationAccuracy
    ) {
        self.windowsValue = windowsValue
        self.androidValue = androidValue
        self.appleValue = appleValue
    }

    /// Provide an extremely accurate location fix, as needed by navigation apps.
    public static let bestForNavigation = LocationAccuracy(
        windowsValue: WindowsLocationAccuracy(rawValue: 5),
        androidValue: .high,
        appleValue: .bestForNavigation
    )

    /// Provide a very accurate location fix, which will not be used for navigation.
    public static let high = LocationAccuracy(
        windowsValue: .high,
        androidValue: .high,
        appleValue: .best
    )

    /// Provide a location fix accurate to within a few hundred meters.
    public static let placeholderNameA = LocationAccuracy(
        windowsValue: .default,
        androidValue: .balanced,
        appleValue: .hundredMeters
    )

    /// Provide a location fix that is accurate to within a few kilometers.
    public static let placeholderNameB = LocationAccuracy(
        windowsValue: WindowsLocationAccuracy(rawValue: 4000),
        androidValue: .low,
        appleValue: .threeKilometers
    )

    /// Provide a location fix that is only approximate.
    ///
    /// This is the only allowed value if the app doesn't have the fine location permission.
    /// It should be accurate to within 20km.
    public static let coarse = LocationAccuracy(
        // Windows does not have a concept of coarse vs fine location accuracy. However, from the
        // Microsoft documentation: "If Wi-Fi is not available, the data could be accurate to within
        // 10 miles or larger."
        windowsValue: WindowsLocationAccuracy(rawValue: 16094),
        androidValue: .low,
        appleValue: .reduced
    )
}
