import Foundation

public extension SimpleRouter where Destination: DeepLinkableDestination {

    /// Navigate from a custom-scheme deeplink (e.g. `myapp://...`).
    /// Mirrors `Router.navigate(to: URL)` but without tab handling.
    @discardableResult
    func navigate(to url: URL, policy: NavigationPolicy = .replace) -> Bool {
        guard let parsed = URLNavigationHelper.parse(
            url, tabType: NoTab.self, destinationType: Destination.self
        ) else {
            return false
        }
        navigateTo(parsed.destinations, policy: policy)
        return true
    }

    /// Navigate from a Universal Link URL (inline params).
    @discardableResult
    func navigate(
        toUniversalLink url: URL,
        allowedHosts: Set<String>,
        pathPrefix: String? = nil,
        allowedSchemes: Set<String> = ["https"],
        policy: NavigationPolicy = .replace
    ) -> Bool {
        guard let parsed = URLNavigationHelper.parseUniversalLink(
            url,
            allowedHosts: allowedHosts,
            pathPrefix: pathPrefix,
            allowedSchemes: allowedSchemes,
            tabType: NoTab.self,
            destinationType: Destination.self
        ) else {
            return false
        }
        navigateTo(parsed.destinations, policy: policy)
        return true
    }

    /// Config-flavored overload.
    @discardableResult
    func navigate(
        toUniversalLink url: URL,
        config: UniversalLinkConfig,
        policy: NavigationPolicy = .replace
    ) -> Bool {
        navigate(
            toUniversalLink: url,
            allowedHosts: config.allowedHosts,
            pathPrefix: config.pathPrefix,
            allowedSchemes: config.allowedSchemes,
            policy: policy
        )
    }
}

/// Private placeholder TabType for SimpleRouter URL parsing (single case, ignored).
internal enum NoTab: String, TabType {
    case _none
}
