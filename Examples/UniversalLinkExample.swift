import SwiftUI
import AppRouterPlus

// MARK: - Types

enum ULTab: String, TabType, CaseIterable {
    case home, profile
}

enum ULDestination: DeepLinkableDestination {
    case home
    case profile(userId: String)

    static func path(for d: ULDestination) -> String {
        switch d {
        case .home: return "home"
        case .profile: return "profile"
        }
    }

    static func from(path: String, fullPath: [String], parameters: [String: [String]]) -> ULDestination? {
        switch path {
        case "home": return .home
        case "profile":
            guard let uid = parameters["userId"]?.last else { return nil }
            return .profile(userId: uid)
        default: return nil
        }
    }
}

enum ULSheet: String, SheetType {
    case settings
    var id: String { rawValue }
}

// MARK: - Config (declare once)

extension UniversalLinkConfig {
    static let example = UniversalLinkConfig(
        allowedHosts: ["example.com"]
    )
}

// MARK: - Demo View

struct UniversalLinkDemoView: View {
    @State var router = Router<ULTab, ULDestination, ULSheet>(initialTab: .home)

    var body: some View {
        TabView(selection: $router.selectedTab) {
            NavigationStack(path: router.binding(for: .home)) {
                Text("Home root")
                    .navigationDestination(for: ULDestination.self) { dest in
                        switch dest {
                        case .home: Text("Home")
                        case .profile(let uid): Text("Profile \(uid)")
                        }
                    }
            }
            .tabItem { Label("Home", systemImage: "house") }
            .tag(ULTab.home)

            NavigationStack(path: router.binding(for: .profile)) {
                Text("Profile root")
                    .navigationDestination(for: ULDestination.self) { dest in
                        switch dest {
                        case .home: Text("Home")
                        case .profile(let uid): Text("Profile \(uid)")
                        }
                    }
            }
            .tabItem { Label("Profile", systemImage: "person") }
            .tag(ULTab.profile)
        }
        // Custom-scheme deeplink: myapp://home?tab=profile
        .onOpenURL { url in
            _ = router.navigate(to: url)
        }
        // Universal Link: https://example.com/profile?userId=42&tab=profile
        .onContinueUserActivity(AppRouterBrowseWebActivityType) { activity in
            _ = router.handleUserActivity(activity, config: .example)
        }
    }
}

// MARK: - Build a shareable UL

func makeShareLink(userId: String) -> URL? {
    URLNavigationHelper.buildUniversalLink(
        host: "example.com",
        tab: ULTab.profile,
        destinations: [ULDestination.profile(userId: userId)],
        extraQuery: ["userId": userId]
    )
}
