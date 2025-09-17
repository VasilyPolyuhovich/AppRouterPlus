import Foundation

/// Marker protocol for tabs.
public protocol TabType: Hashable, CaseIterable, Sendable {}

/// Destination is a typed, codable route node.
/// Conformers should implement a *stable* path segment and a URL decoder.
public protocol DestinationType: Hashable, Codable, Sendable {
    /// Return a stable path component for the given destination.
    /// Example: `.detail(id: UUID())` -> "detail"
    static func path(for destination: Self) -> String

    /// Decode a destination from the last path component.
    /// - Parameters:
    ///   - path: the last segment, e.g. "detail"
    ///   - fullPath: all path segments including host, e.g. ["users","detail"]
    ///   - parameters: query parameters as a multi-map
    static func from(path: String, fullPath: [String], parameters: [String:[String]]) -> Self?
}

/// Typed sheet entity with a *stable* identifier.
/// Prefer returning `rawValue` or `self` as ID to avoid `hashValue` pitfalls.
public protocol SheetType: Identifiable, Hashable, Sendable where ID: Hashable {}
