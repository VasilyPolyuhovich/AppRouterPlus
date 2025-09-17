import Foundation
import SwiftUI

public enum NavigationPolicy: Sendable {
    /// Replace the entire path for target tab.
    case replace
    /// Append destination(s) to the end of the path.
    case append
    /// Replace the last element of the path with the destination(s).
    case replaceTop
}

public enum RouterError: Error, Sendable {
    case unknownRoute
    case invalidParameters
    case noActiveTab
}

extension Array {
    /// Safely pop last element and return it.
    @discardableResult
    mutating func popLastSafe() -> Element? {
        isEmpty ? nil : removeLast()
    }
}

extension Binding {
    /// Build a Binding from get/set closures.
    public static func build(
        get: @Sendable @escaping () -> Value,
        set: @Sendable @escaping (Value) -> Void
    ) -> Binding<Value> {
        Binding(get: get, set: set)
    }
}
