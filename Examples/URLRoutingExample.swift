import SwiftUI
import AppRouterPlus

enum AppTab: String, TabType, CaseIterable {
    case home, profile
}

enum Destination: DestinationType {
    case home
    case detail(id: String)
    case profile(userId: String)

    static func path(for destination: Destination) -> String {
        switch destination {
        case .home: return "home"
        case .detail: return "detail"
        case .profile: return "profile"
        }
    }

    static func from(path: String, fullPath: [String], parameters: [String : [String]]) -> Destination? {
        switch path {
        case "home":
            return .home
        case "detail":
            if let id = parameters["id"]?.last { return .detail(id: id) }
            return nil
        case "profile":
            if let uid = parameters["userId"]?.last { return .profile(userId: uid) }
            return nil
        default:
            return nil
        }
    }
}

enum Sheet: String, SheetType {
    case settings
    var id: String { rawValue } // stable
}

// MVVM adapter
@MainActor
final class RouterAdapter {
    private let router: Router<AppTab, Destination, Sheet>
    init(_ router: Router<AppTab, Destination, Sheet>) { self.router = router }

    func openDetails(_ id: String) { router.navigateTo(.detail(id: id), policy: .append) }
    func openProfile(_ id: String) {
        router.selectedTab = .profile
        router.navigateTo(.profile(userId: id), policy: .append)
    }
    func openSettings() { _ = router.presentSheet(.settings) }
}

// SwiftUI demo scaffolding
struct DemoRootView: View {
    @State var router = Router<AppTab, Destination, Sheet>(initialTab: .home)

    var body: some View {
        TabView(selection: $router.selectedTab) {
            NavigationStack(path: router.binding(for: .home)) {
                HomeView(vm: RouterAdapter(router))
                    .navigationDestination(for: Destination.self) { dest in
                        switch dest {
                        case .home: Text("Home")
                        case .detail(let id): Text("Detail \(id)")
                        case .profile(let uid): Text("Profile \(uid)")
                        }
                    }
            }
            .tabItem { Label("Home", systemImage: "house") }
            .tag(AppTab.home)

            NavigationStack(path: router.binding(for: .profile)) {
                ProfileView()
                    .navigationDestination(for: Destination.self) { dest in
                        switch dest {
                        case .home: Text("Home")
                        case .detail(let id): Text("Detail \(id)")
                        case .profile(let uid): Text("Profile \(uid)")
                        }
                    }
            }
            .tabItem { Label("Profile", systemImage: "person") }
            .tag(AppTab.profile)
        }
        .sheet(item: router.activeSheetBinding) { sheet in
            switch sheet {
            case .settings: Text("Settings Sheet")
            }
        }
        // Deep link demo: myapp://home/detail?id=123&tab=profile
        .onOpenURL { url in _ = router.navigate(to: url) }
    }
}

struct HomeView: View {
    let vm: RouterAdapter
    var body: some View {
        VStack(spacing: 12) {
            Button("Open details") { vm.openDetails(UUID().uuidString) }
            Button("Open profile 42") { vm.openProfile("42") }
            Button("Settings sheet") { vm.openSettings() }
        }
        .navigationTitle("Home")
    }
}

struct ProfileView: View {
    var body: some View { Text("Profile root") }
}
