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
    case onboarding
    case login
    var id: String { rawValue } // stable
}

// MARK: - Example Interceptors

/// Auth guard interceptor - blocks navigation to protected screens
struct AuthInterceptor: NavigationInterceptor {
    func shouldNavigate(from: Destination?, to: Destination) async -> Bool {
        // Simulate auth check
        let isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        
        // Profile requires authentication
        if case .profile = to {
            if !isLoggedIn {
                print("🔒 Navigation blocked: User not logged in")
                return false
            }
        }
        
        return true
    }
}

/// Analytics interceptor - tracks all navigation events
struct AnalyticsInterceptor: NavigationInterceptor {
    func shouldNavigate(from: Destination?, to: Destination) async -> Bool {
        // Simulate analytics tracking
        let fromName = from.map { "\($0)" } ?? "root"
        let toName = "\(to)"
        print("📊 Analytics: Navigation from \(fromName) to \(toName)")
        
        // Always allow navigation
        return true
    }
}

// MVVM adapter
@MainActor
final class RouterAdapter {
    private let router: Router<AppTab, Destination, Sheet>
    init(_ router: Router<AppTab, Destination, Sheet>) { self.router = router }

    func openDetails(_ id: String) async {
        await router.navigateToAsync(.detail(id: id), policy: .append)
    }
    
    func openProfile(_ id: String) async {
        router.selectedTab = .profile
        let success = await router.navigateToAsync(.profile(userId: id), policy: .append)
        
        // If blocked by interceptor, show login
        if !success {
            _ = router.presentSheet(.login)
        }
    }
    
    func openSettings() { _ = router.presentSheet(.settings) }
    func openOnboarding() { _ = router.presentFullScreenCover(.onboarding) }
    func toggleLogin() {
        let isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        UserDefaults.standard.set(!isLoggedIn, forKey: "isLoggedIn")
    }
}

// SwiftUI demo scaffolding
struct DemoRootView: View {
    @State var router = Router<AppTab, Destination, Sheet>(initialTab: .home)
    
    init() {
        // Setup interceptors
        _router = State(initialValue: {
            let r = Router<AppTab, Destination, Sheet>(initialTab: .home)
            r.addInterceptor(AnalyticsInterceptor())
            r.addInterceptor(AuthInterceptor())
            return r
        }())
    }

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
            case .settings:
                Text("Settings Sheet")
            case .login:
                VStack(spacing: 20) {
                    Text("Login Required")
                        .font(.title)
                    Text("Please log in to access this feature")
                        .foregroundColor(.secondary)
                    Button("Login") {
                        UserDefaults.standard.set(true, forKey: "isLoggedIn")
                        router.dismissSheet()
                    }
                    .buttonStyle(.borderedProminent)
                    Button("Cancel") {
                        router.dismissSheet()
                    }
                }
                .padding()
            case .onboarding:
                EmptyView() // handled by fullScreenCover
            }
        }
        .fullScreenCover(item: router.activeFullScreenCoverBinding) { sheet in
            switch sheet {
            case .onboarding:
                VStack(spacing: 20) {
                    Text("Onboarding")
                        .font(.largeTitle)
                    Text("Full-screen immersive experience")
                        .foregroundColor(.secondary)
                    Button("Complete") {
                        router.dismissFullScreenCover()
                    }
                    .buttonStyle(.borderedProminent)
                }
            case .settings: EmptyView() // handled by sheet
            }
        }
        // Deep link demo: myapp://home/detail?id=123&tab=profile
        .onOpenURL { url in _ = router.navigate(to: url) }
    }
}

struct HomeView: View {
    let vm: RouterAdapter
    @State private var isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
    
    var body: some View {
        VStack(spacing: 12) {
            Text(isLoggedIn ? "🔓 Logged In" : "🔒 Not Logged In")
                .font(.headline)
                .padding()
            
            Button("Open details") {
                Task { await vm.openDetails(UUID().uuidString) }
            }
            
            Button("Open profile 42 (protected)") {
                Task { await vm.openProfile("42") }
            }
            
            Button("Settings sheet") { vm.openSettings() }
            Button("Onboarding (full-screen)") { vm.openOnboarding() }
            
            Divider().padding()
            
            Button(isLoggedIn ? "Logout" : "Login") {
                vm.toggleLogin()
                isLoggedIn.toggle()
            }
            .buttonStyle(.bordered)
        }
        .navigationTitle("Home")
    }
}

struct ProfileView: View {
    var body: some View { Text("Profile root") }
}
