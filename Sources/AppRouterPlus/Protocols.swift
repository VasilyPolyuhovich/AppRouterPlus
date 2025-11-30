import Foundation

/// Marker protocol for tabs.
public protocol TabType: Hashable, CaseIterable, Sendable {}

/// Base protocol for navigation destinations.
/// NO Codable requirement - destinations can contain ViewModels, closures, or any types.
/// For deep link support, conform to `DeepLinkableDestination` instead.
public protocol DestinationType: Hashable, Sendable {}

/// Extended protocol for destinations that support deep linking via URLs.
/// Adds Codable requirement and URL serialization methods.
/// Use this when you need `Router.navigate(to: URL)` functionality.
public protocol DeepLinkableDestination: DestinationType, Codable {
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

/// Navigation interceptor for middleware-style navigation hooks.
/// Interceptors run before navigation and can block or allow transitions.
/// Use cases: auth guards, unsaved changes warnings, analytics, feature flags.
public protocol NavigationInterceptor<Destination>: Sendable {
    associatedtype Destination: DestinationType
    
    /// Called before navigation. Return false to block the transition.
    /// - Parameters:
    ///   - from: Current destination (nil if at root)
    ///   - to: Target destination
    /// - Returns: true to allow navigation, false to block
    func shouldNavigate(from: Destination?, to: Destination) async -> Bool
}
