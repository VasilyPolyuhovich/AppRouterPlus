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
}

/// Private placeholder TabType for SimpleRouter URL parsing (single case, ignored).
internal enum NoTab: String, TabType {
    case _none
}
