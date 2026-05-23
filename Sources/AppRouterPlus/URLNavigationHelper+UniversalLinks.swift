import Foundation

public extension URLNavigationHelper {

    /// Parse a Universal Link URL into `(tab, destinations)`.
    /// - Returns: `nil` if scheme/host/prefix validation fails or any path segment is unmappable.
    static func parseUniversalLink<Tab, Destination>(
        _ url: URL,
        allowedHosts: Set<String>,
        pathPrefix: String? = nil,
        allowedSchemes: Set<String> = ["https"],
        tabType: Tab.Type,
        destinationType: Destination.Type
    ) -> (tab: Tab?, destinations: [Destination])?
        where Tab: TabType, Destination: DeepLinkableDestination
    {
        // Normalize (idempotent for already-normalized inputs from UniversalLinkConfig)
        let normHosts = Set(allowedHosts.map { $0.lowercased() })
        let normSchemes = Set(allowedSchemes.map { $0.lowercased() })
        let normPrefix: String? = pathPrefix.map { p in
            var s = p
            while s.count > 1 && s.hasSuffix("/") { s.removeLast() }
            return s
        }

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let scheme = components.scheme?.lowercased(),
              normSchemes.contains(scheme),
              let host = components.host?.lowercased(),
              normHosts.contains(host)
        else { return nil }

        // Validate / strip path prefix per-segment
        var remaining = components.path
        if let prefix = normPrefix {
            if remaining == prefix || remaining == prefix + "/" {
                remaining = ""
            } else if remaining.hasPrefix(prefix + "/") {
                remaining = String(remaining.dropFirst(prefix.count))
            } else {
                return nil
            }
        }

        // Build query multi-map
        var params: [String: [String]] = [:]
        if let items = components.queryItems {
            for item in items {
                params[item.name, default: []].append(item.value ?? "")
            }
        }

        // Resolve tab from query (LAST wins, matches existing parse)
        var targetTab: Tab? = nil
        if let rawTab = params["tab"]?.last {
            for t in Tab.allCases {
                if String(describing: t) == rawTab { targetTab = t; break }
                if let r = t as? any CustomStringConvertible, r.description == rawTab { targetTab = t; break }
            }
        }

        // Split remaining path into segments
        let segments = remaining
            .split(separator: "/", omittingEmptySubsequences: true)
            .map(String.init)

        guard !segments.isEmpty else {
            return (targetTab, [])
        }

        var destinations: [Destination] = []
        for (i, seg) in segments.enumerated() {
            let subpath = Array(segments.prefix(i + 1))
            if let dest = Destination.from(path: seg, fullPath: subpath, parameters: params) {
                destinations.append(dest)
            } else {
                return nil
            }
        }
        return (targetTab, destinations)
    }

    /// Config-flavored overload of `parseUniversalLink`.
    static func parseUniversalLink<Tab, Destination>(
        _ url: URL,
        config: UniversalLinkConfig,
        tabType: Tab.Type,
        destinationType: Destination.Type
    ) -> (tab: Tab?, destinations: [Destination])?
        where Tab: TabType, Destination: DeepLinkableDestination
    {
        parseUniversalLink(
            url,
            allowedHosts: config.allowedHosts,
            pathPrefix: config.pathPrefix,
            allowedSchemes: config.allowedSchemes,
            tabType: tabType,
            destinationType: destinationType
        )
    }
}
