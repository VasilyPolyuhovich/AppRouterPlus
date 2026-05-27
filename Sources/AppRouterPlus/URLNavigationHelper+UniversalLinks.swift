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

    /// Build a Universal Link URL with a tab query parameter.
    /// Symmetric with `build(scheme:tab:destinations:extraQuery:)` but for UL.
    /// - Note: Does NOT validate host against any allow-list (parse-time concern).
    /// - Note: `extraQuery` is single-value per key; for multi-value URLs build manually.
    static func buildUniversalLink<Tab, Destination>(
        host: String,
        scheme: String = "https",
        pathPrefix: String? = nil,
        tab: Tab?,
        destinations: [Destination],
        extraQuery: [String: String] = [:]
    ) -> URL?
        where Tab: TabType, Destination: DeepLinkableDestination
    {
        _buildUniversalLink(
            host: host,
            scheme: scheme,
            pathPrefix: pathPrefix,
            tabRaw: tab.map { String(describing: $0) },
            destinations: destinations,
            extraQuery: extraQuery
        )
    }

    /// Build a Universal Link URL without a tab parameter.
    /// Convenience for callers that don't use tabs (e.g. SimpleRouter) or don't need to encode one.
    static func buildUniversalLink<Destination>(
        host: String,
        scheme: String = "https",
        pathPrefix: String? = nil,
        destinations: [Destination],
        extraQuery: [String: String] = [:]
    ) -> URL?
        where Destination: DeepLinkableDestination
    {
        _buildUniversalLink(
            host: host,
            scheme: scheme,
            pathPrefix: pathPrefix,
            tabRaw: nil,
            destinations: destinations,
            extraQuery: extraQuery
        )
    }

    private static func _buildUniversalLink<Destination>(
        host: String,
        scheme: String,
        pathPrefix: String?,
        tabRaw: String?,
        destinations: [Destination],
        extraQuery: [String: String]
    ) -> URL?
        where Destination: DeepLinkableDestination
    {
        let normPrefix: String? = pathPrefix.map { p in
            var s = p
            while s.count > 1 && s.hasSuffix("/") { s.removeLast() }
            return s
        }

        var comps = URLComponents()
        comps.scheme = scheme
        comps.host = host

        var parts: [String] = []
        if let prefix = normPrefix, !prefix.isEmpty {
            let trimmed = prefix.hasPrefix("/") ? String(prefix.dropFirst()) : prefix
            if !trimmed.isEmpty { parts.append(trimmed) }
        }
        for dest in destinations {
            parts.append(Destination.path(for: dest))
        }
        comps.path = parts.isEmpty ? "/" : "/" + parts.joined(separator: "/")

        var items: [URLQueryItem] = []
        if let tabRaw {
            items.append(URLQueryItem(name: "tab", value: tabRaw))
        }
        for (k, v) in extraQuery {
            items.append(URLQueryItem(name: k, value: v))
        }
        if !items.isEmpty {
            comps.queryItems = items
        }

        return comps.url
    }
}
