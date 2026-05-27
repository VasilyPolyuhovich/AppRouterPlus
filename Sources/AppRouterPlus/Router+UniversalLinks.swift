import Foundation

public extension Router where Destination: DeepLinkableDestination {

    /// Navigate from a Universal Link URL (inline params).
    /// - Returns: `false` if scheme/host/prefix validation fails or any path segment unmappable.
    /// - Note: When `deepPush == true` and `policy == .replace`, navigation completes
    ///         asynchronously on the next MainActor ticks; this method returns immediately.
    @discardableResult
    func navigate(
        toUniversalLink url: URL,
        allowedHosts: Set<String>,
        pathPrefix: String? = nil,
        allowedSchemes: Set<String> = ["https"],
        policy: NavigationPolicy = .replace,
        deepPush: Bool = true
    ) -> Bool {
        guard let parsed = URLNavigationHelper.parseUniversalLink(
            url,
            allowedHosts: allowedHosts,
            pathPrefix: pathPrefix,
            allowedSchemes: allowedSchemes,
            tabType: Tab.self,
            destinationType: Destination.self
        ) else {
            return false
        }
        if let t = parsed.tab { selectedTab = t }
        if deepPush, policy == .replace {
            return deepPushTo(parsed.destinations)
        } else {
            navigateTo(parsed.destinations, policy: policy, for: selectedTab)
            return true
        }
    }

    /// Config-flavored overload.
    @discardableResult
    func navigate(
        toUniversalLink url: URL,
        config: UniversalLinkConfig,
        policy: NavigationPolicy = .replace,
        deepPush: Bool = true
    ) -> Bool {
        navigate(
            toUniversalLink: url,
            allowedHosts: config.allowedHosts,
            pathPrefix: config.pathPrefix,
            allowedSchemes: config.allowedSchemes,
            policy: policy,
            deepPush: deepPush
        )
    }
}
