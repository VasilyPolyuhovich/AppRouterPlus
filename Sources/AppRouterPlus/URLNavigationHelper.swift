import Foundation

public enum URLNavigationHelper {

    /// Parse a URL into an optional target tab and an ordered list of destinations.
    /// - Note: Only works with DeepLinkableDestination conforming types.
    public static func parse<Tab, Destination>(
        _ url: URL,
        tabType: Tab.Type,
        destinationType: Destination.Type
    ) -> (tab: Tab?, destinations: [Destination])? where Tab: TabType, Destination: DeepLinkableDestination {

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }

        // Collect query items as a multimap: [name: [values]]
        var params: [String:[String]] = [:]
        if let items = components.queryItems {
            for item in items {
                let key = item.name
                let value = item.value ?? ""
                params[key, default: []].append(value)
            }
        }

        // Resolve tab from query parameter if possible
        var targetTab: Tab? = nil
        if let rawTab = params["tab"]?.last {
            // try to resolve the tab by matching its CaseIterable string description
            for t in Tab.allCases {
                if String(describing: t) == rawTab { targetTab = t; break }
                // also try rawValue when Tab is RawRepresentable
                if let r = t as? any CustomStringConvertible, r.description == rawTab { targetTab = t; break }
            }
        }

        // Build path segments: host + path components
        let host = components.host ?? ""
        let pathSegments = url
            .path
            .split(separator: "/", omittingEmptySubsequences: true)
            .map(String.init)

        var full: [String] = []
        if !host.isEmpty { full.append(host) }
        full.append(contentsOf: pathSegments)

        guard !full.isEmpty else {
            // allow bare scheme://?tab=... with zero destinations
            return (targetTab, [])
        }

        // Map each segment to a Destination using DestinationType.from(...)
        var destinations: [Destination] = []
        for (i, seg) in full.enumerated() {
            let subpath = Array(full.prefix(i+1))
            if let dest = Destination.from(path: seg, fullPath: subpath, parameters: params) {
                destinations.append(dest)
            } else {
                // if any segment can't map, consider URL invalid
                return nil
            }
        }

        return (targetTab, destinations)
    }

    /// Build a stable deep link URL from destinations and an optional tab.
    /// Example: scheme://host/path?tab=profile&foo=bar
    /// - Note: Only works with DeepLinkableDestination conforming types.
    public static func build<Tab, Destination>(
        scheme: String,
        tab: Tab? = nil,
        destinations: [Destination],
        extraQuery: [String:String] = [:]
    ) -> URL? where Tab: TabType, Destination: DeepLinkableDestination {

        guard !destinations.isEmpty else {
            var comps = URLComponents()
            comps.scheme = scheme
            comps.host = nil
            comps.path = "/"
            comps.queryItems = buildQuery(tab: tab, extra: extraQuery)
            return comps.url
        }

        let head = Destination.path(for: destinations[0])
        let tail = destinations.dropFirst().map { Destination.path(for: $0) }
        var comps = URLComponents()
        comps.scheme = scheme
        comps.host = head.isEmpty ? nil : head
        comps.path = "/" + tail.joined(separator: "/")
        comps.queryItems = buildQuery(tab: tab, extra: extraQuery)
        return comps.url
    }

    private static func buildQuery<Tab: TabType>(tab: Tab?, extra: [String:String]) -> [URLQueryItem]? {
        var items: [URLQueryItem] = []
        if let tab = tab {
            items.append(URLQueryItem(name: "tab", value: String(describing: tab)))
        }
        for (k, v) in extra { items.append(URLQueryItem(name: k, value: v)) }
        return items.isEmpty ? nil : items
    }
}
