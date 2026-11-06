public struct LocationPermissions: OptionSet, Sendable, Hashable, BitwiseCopyable {
    public var rawValue: UInt8
    
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    
    public static let coarse = LocationPermissions(rawValue: 1 << 0)
    public static let fine = LocationPermissions(rawValue: 1 << 1)
    public static let background = LocationPermissions(rawValue: 1 << 2)
}

public enum LocationPermissionStatus: Sendable, Hashable, BitwiseCopyable {
    case granted, denied, partiallyGranted, notPrompted
}
