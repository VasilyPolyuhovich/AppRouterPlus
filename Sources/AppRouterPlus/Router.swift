import Foundation
import SwiftUI
import Observation

@MainActor
@Observable
public final class Router<Tab, Destination, Sheet> where Tab: TabType, Destination: DestinationType, Sheet: SheetType {

    // MARK: - Public state
    public var selectedTab: Tab
    /// Paths per tab
    private var paths: [Tab: [Destination]]
    /// Multi-sheet stack, top-most sheet is last.
    public var presentedSheets: [Sheet] = []

    // MARK: - Init
    public init(initialTab: Tab, initialPaths: [Tab:[Destination]]? = nil) {
        self.selectedTab = initialTab
        var dict: [Tab:[Destination]] = [:]
        for t in Tab.allCases { dict[t] = [] }
        if let initialPaths { for (k,v) in initialPaths { dict[k] = v } }
        self.paths = dict
    }

    // MARK: - Path access

    /// Get or set the path for a given tab.
    public subscript(pathFor tab: Tab) -> [Destination] {
        get { paths[tab] ?? [] }
        set { paths[tab] = newValue }
    }

    /// Provide a Binding<[Destination]> to use with NavigationStack(path:).
    public func binding(for tab: Tab) -> Binding<[Destination]> {
        Binding(get: { self.paths[tab] ?? [] },
                set: { self.paths[tab] = $0 })
    }

    /// Active sheet binding for `.sheet(item:)` that manages the stack.
    public var activeSheetBinding: Binding<Sheet?> {
        Binding<Sheet?>(
            get: { self.presentedSheets.last },
            set: { newValue in
                if let value = newValue {
                    // push if different
                    if self.presentedSheets.last != value {
                        self.presentedSheets.append(value)
                    }
                } else {
                    // pop
                    _ = self.presentedSheets.popLastSafe()
                }
            }
        )
    }

    // MARK: - Sheet API

    @discardableResult
    public func presentSheet(_ sheet: Sheet) -> Sheet {
        presentedSheets.append(sheet)
        return sheet
    }

    public func dismissSheet() {
        _ = presentedSheets.popLastSafe()
    }

    public func dismissSheets(count: Int) {
        guard count > 0 else { return }
        (0..<count).forEach { _ in _ = presentedSheets.popLastSafe() }
    }

    public func dismissSheets(to target: Sheet) {
        while let last = presentedSheets.last, last != target {
            _ = presentedSheets.popLastSafe()
        }
    }

    // MARK: - Navigation API (typed)

    public func navigateTo(_ destination: Destination, policy: NavigationPolicy = .append, for tab: Tab? = nil) {
        let t = tab ?? selectedTab
        var path = paths[t] ?? []
        switch policy {
        case .replace:
            path = [destination]
        case .append:
            path.append(destination)
        case .replaceTop:
            if path.isEmpty { path = [destination] }
            else { _ = path.popLastSafe(); path.append(destination) }
        }
        paths[t] = path
    }

    public func navigateTo(_ destinations: [Destination], policy: NavigationPolicy = .replace, for tab: Tab? = nil) {
        let t = tab ?? selectedTab
        switch policy {
        case .replace:
            paths[t] = destinations
        case .append:
            paths[t, default: []].append(contentsOf: destinations)
        case .replaceTop:
            var path = paths[t] ?? []
            if destinations.isEmpty { return }
            if path.isEmpty {
                path = destinations
            } else {
                _ = path.popLastSafe()
                path.append(contentsOf: destinations)
            }
            paths[t] = path
        }
    }

    public func popNavigation(for tab: Tab? = nil) {
        let t = tab ?? selectedTab
        var path = paths[t] ?? []
        _ = path.popLastSafe()
        paths[t] = path
    }

    public func popToRoot(for tab: Tab? = nil) {
        let t = tab ?? selectedTab
        paths[t] = []
    }

    public func popTo(where predicate: (Destination) -> Bool, for tab: Tab? = nil) {
        let t = tab ?? selectedTab
        var path = paths[t] ?? []
        while let last = path.last, !predicate(last) {
            _ = path.popLastSafe()
        }
        paths[t] = path
    }

    // MARK: - Deep links

    /// Parse and navigate from a URL.
    /// - Returns: true if URL was successfully applied.
    @discardableResult
    public func navigate(to url: URL, policy: NavigationPolicy = .replace, deepPush: Bool = true) -> Bool {
        guard let parsed = URLNavigationHelper.parse(url, tabType: Tab.self, destinationType: Destination.self) else {
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

    /// Perform multi-step push for better SwiftUI stability.
    private func deepPushTo(_ destinations: [Destination]) -> Bool {
        let t = selectedTab
        paths[t] = []
        if destinations.isEmpty { return true }
        // Append step-by-step to reduce glitches.
        Task { @MainActor [weak self] in
            guard let self else { return }
            for dest in destinations {
                self.paths[t, default: []].append(dest)
                // give SwiftUI a chance to process each step
                try? await Task.sleep(nanoseconds: 15_000_000) // 15ms
            }
        }
        return true
    }
}
