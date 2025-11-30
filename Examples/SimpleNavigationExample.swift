import SwiftUI
import AppRouterPlus

// MARK: - Example: Internal Navigation Only (No Deep Links)
//
// This example shows how to use AppRouterPlus WITHOUT deep linking.
// Benefits:
// - No Codable requirement for destinations
// - Can pass ViewModels, closures, or any complex types directly
// - Simpler setup for internal-only navigation

// MARK: - Types

enum SimpleTab: String, TabType, CaseIterable {
    case home
    case profile
}

/// Internal-only destinations - NO Codable needed!
/// Can contain ANY types: ViewModels, closures, complex objects
enum SimpleDestination: DestinationType {
    case home
    case detail(viewModel: DetailViewModel)  // ✅ Non-Codable ViewModel!
    case settings(config: AppConfig)         // ✅ Complex config object!
    case editor(onSave: @Sendable () -> Void) // ✅ Closures allowed!
}

/// Example ViewModel - NOT Codable, NOT Hashable (normally)
/// We make it Hashable for SwiftUI navigation
@Observable
final class DetailViewModel: Hashable {
    let id: UUID
    var title: String
    var isLoading: Bool = false
    
    init(id: UUID = UUID(), title: String) {
        self.id = id
        self.title = title
    }
    
    @MainActor
    func load() async {
        isLoading = true
        // Simulate network request
        try? await Task.sleep(nanoseconds: 500_000_000)
        title = "Loaded: \(title)"
        isLoading = false
    }
    
    static func == (lhs: DetailViewModel, rhs: DetailViewModel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Complex configuration object - also not Codable
struct AppConfig: Hashable {
    var theme: Theme
    var debugMode: Bool
    var apiEndpoint: String
    
    enum Theme: String, Hashable {
        case light, dark, system
    }
}

enum SimpleSheet: String, SheetType {
    case help
    var id: String { rawValue }
}

// MARK: - Main View

struct SimpleNavigationApp: View {
    @State private var router = Router<SimpleTab, SimpleDestination, SimpleSheet>(
        initialTab: .home
    )
    
    var body: some View {
        TabView(selection: $router.selectedTab) {
            NavigationStack(path: router.binding(for: .home)) {
                SimpleHomeView()
                    .navigationDestination(for: SimpleDestination.self) { dest in
                        destinationView(for: dest)
                    }
            }
            .tabItem { Label("Home", systemImage: "house") }
            .tag(SimpleTab.home)
            
            NavigationStack(path: router.binding(for: .profile)) {
                Text("Profile")
                    .navigationDestination(for: SimpleDestination.self) { dest in
                        destinationView(for: dest)
                    }
            }
            .tabItem { Label("Profile", systemImage: "person") }
            .tag(SimpleTab.profile)
        }
        .environment(router)
        .sheet(item: router.activeSheetBinding) { sheet in
            switch sheet {
            case .help:
                Text("Help Sheet")
            }
        }
    }
    
    @ViewBuilder
    func destinationView(for destination: SimpleDestination) -> some View {
        switch destination {
        case .home:
            Text("Home")
        case .detail(let viewModel):
            SimpleDetailView(viewModel: viewModel)
        case .settings(let config):
            SimpleSettingsView(config: config)
        case .editor(let onSave):
            SimpleEditorView(onSave: onSave)
        }
    }
}

// MARK: - Child Views

struct SimpleHomeView: View {
    @Environment(Router<SimpleTab, SimpleDestination, SimpleSheet>.self) var router
    
    var body: some View {
        List {
            Section("Navigation Examples") {
                // Pass ViewModel directly - no ID conversion needed!
                Button("Open Detail with ViewModel") {
                    let vm = DetailViewModel(title: "Example Item")
                    router.navigateTo(.detail(viewModel: vm))
                }
                
                // Pass complex config
                Button("Open Settings with Config") {
                    let config = AppConfig(
                        theme: .dark,
                        debugMode: true,
                        apiEndpoint: "https://api.example.com"
                    )
                    router.navigateTo(.settings(config: config))
                }
                
                // Pass closure for callback
                Button("Open Editor with Callback") {
                    router.navigateTo(.editor(onSave: {
                        print("✅ Saved!")
                    }))
                }
            }
            
            Section("Notes") {
                Text("• No Codable conformance needed")
                Text("• ViewModels passed directly")
                Text("• Closures work in destinations")
                Text("• Deep links NOT supported")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .navigationTitle("Simple Navigation")
    }
}

struct SimpleDetailView: View {
    @Bindable var viewModel: DetailViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            if viewModel.isLoading {
                ProgressView()
            } else {
                Text(viewModel.title)
                    .font(.title)
            }
            
            Button("Load Data") {
                Task { await viewModel.load() }
            }
        }
        .navigationTitle("Detail")
    }
}

struct SimpleSettingsView: View {
    let config: AppConfig
    
    var body: some View {
        List {
            LabeledContent("Theme", value: config.theme.rawValue)
            LabeledContent("Debug Mode", value: config.debugMode ? "On" : "Off")
            LabeledContent("API Endpoint", value: config.apiEndpoint)
        }
        .navigationTitle("Settings")
    }
}

struct SimpleEditorView: View {
    let onSave: @Sendable () -> Void
    @Environment(Router<SimpleTab, SimpleDestination, SimpleSheet>.self) var router
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Editor")
                .font(.title)
            
            Button("Save & Close") {
                onSave()
                router.popNavigation()
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Editor")
    }
}

// MARK: - Preview

#Preview {
    SimpleNavigationApp()
}
