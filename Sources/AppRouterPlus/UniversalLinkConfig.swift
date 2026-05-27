import Foundation

/// Validation parameters for Universal Link parsing.
/// Bundle once and pass via the `config:` overloads of `parseUniversalLink`,
/// `Router.navigate(toUniversalLink:)`, and `Router.handleUserActivity(_:)`.
public struct UniversalLinkConfig: Sendable, Hashable {
    /// Allowed hosts (lowercased at init).
    public let allowedHosts: Set<String>
    /// Optional path prefix to strip before destination parsing
    /// (trailing slashes normalized at init).
    public let pathPrefix: String?
    /// Allowed URL schemes (lowercased at init). Default ["https"].
    public let allowedSchemes: Set<String>

    public init(
        allowedHosts: Set<String>,
        pathPrefix: String? = nil,
        allowedSchemes: Set<String> = ["https"]
    ) {
        self.allowedHosts = Set(allowedHosts.map { $0.lowercased() })
        self.allowedSchemes = Set(allowedSchemes.map { $0.lowercased() })
        if var p = pathPrefix {
            while p.count > 1 && p.hasSuffix("/") { p.removeLast() }
            self.pathPrefix = p
        } else {
            self.pathPrefix = nil
        }
    }
}
