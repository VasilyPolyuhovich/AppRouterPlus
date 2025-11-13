# AppRouterPlus

A simple router for SwiftUI iOS 18+ with support for:
- stacks for each tab (`NavigationStack`),
- deeplinks with **stable** segments,
- navigation policies (`replace`, `append`, `replaceTop`),
- multi-layer `sheet` and `fullScreenCover` stacks,
- **navigation interceptors** for auth guards, analytics, and middleware,
- MVVM-friendly via a thin adapter.

> This is an independent implementation that fixes common shortcomings: unstable `Sheet.id`, incorrect builder URL, missing `tab` parameter in deeplink, one-step deep stack building, etc.

## Installation

### Via Swift Package Manager (locally)
1. Download the archive or copy the `AppRouterPlus` folder into your project.
2. In Xcode: `File → Add Packages… → Add Local…` and specify the path to this folder.

### Minimum requirements
- iOS 18+
- Swift 6 (`swift-tools-version: 6.0`)

## Quick Start

1) Declare types:

```swift
enum AppTab: String, TabType, CaseIterable { case home, profile }

enum Destination: DestinationType {
  case home
  case detail(id: String)

  static func path(for d: Destination) -> String {
    switch d { case .home: "home"; case .detail: "detail" }
  }

  static func from(path: String, fullPath: [String], parameters: [String:[String]]) -> Destination? {
    switch path {
    case "home": return .home
    case "detail":
      guard let id = parameters["id"]?.last else { return nil }
      return .detail(id: id)
    default: return nil
    }
  }
}

enum Sheet: String, SheetType { case settings; var id: String { rawValue } } // stable ID
```

2) Mount the router at the root and connect with `TabView` and `NavigationStack`:

```swift
@State var router = Router<AppTab, Destination, Sheet>(initialTab: .home)

TabView(selection: $router.selectedTab) {
  NavigationStack(path: router.binding(for: .home)) { /* ... */ }
    .tabItem { Label("Home", systemImage: "house") }.tag(AppTab.home)

  NavigationStack(path: router.binding(for: .profile)) { /* ... */ }
    .tabItem { Label("Profile", systemImage: "person") }.tag(AppTab.profile)
}
.sheet(item: router.activeSheetBinding) { sheet in /* build sheet */ }
.fullScreenCover(item: router.activeFullScreenCoverBinding) { sheet in /* build full-screen cover */ }
.onOpenURL { url in _ = router.navigate(to: url) } // deeplink
```

3) Inject a thin adapter into the VM:

```swift
@MainActor final class RouterAdapter {
  private let router: Router<AppTab, Destination, Sheet>
  init(_ router: Router<AppTab, Destination, Sheet>) { self.router = router }

  // Sync navigation (no interceptors)
  func showDetail(_ id: String) { router.navigateTo(.detail(id: id), policy: .append) }
  
  // Async navigation (with interceptors)
  func showProfile(_ id: String) async {
    await router.navigateToAsync(.profile(userId: id))
  }
  
  func showSettings() { _ = router.presentSheet(.settings) }
  func showOnboarding() { _ = router.presentFullScreenCover(.onboarding) }
}
```

## Deeplink

- Any URL in format `scheme://<segment>/<segment>?tab=<tab>&key=value`.
- Parameters are parsed as a multi-map: `[String:[String]]` (duplicate keys supported).
- Stable segments are generated via `Destination.path(for:)`.
- Builder available: `URLNavigationHelper.build(scheme:tab:destinations:extraQuery:)`.

```swift
// Example: myapp://home/detail?id=123&tab=profile
.onOpenURL { url in _ = router.navigate(to: url) }
```

## Navigation policies

```swift
router.navigateTo(.detail(id: "123"), policy: .append)
router.navigateTo([.home, .detail(id: "1")], policy: .replace)
router.popNavigation()
router.popToRoot()
router.popTo { $0 == .home }
```

## Sheets (`sheet`)

- Supports **stack** of sheets: top is the last element.
- Public binding `activeSheetBinding` works conveniently with `.sheet(item:)`.

```swift
.sheet(item: router.activeSheetBinding) { sheet in /* build sheet view */ }
router.presentSheet(.settings)
router.dismissSheet()
router.dismissSheets(count: 2)
```

## Full-Screen Covers (`fullScreenCover`)

- Supports **stack** of full-screen covers: top is the last element.
- Public binding `activeFullScreenCoverBinding` works with `.fullScreenCover(item:)`.
- Use for immersive experiences: onboarding, login, camera, etc.

```swift
.fullScreenCover(item: router.activeFullScreenCoverBinding) { sheet in /* build full-screen view */ }
router.presentFullScreenCover(.onboarding)
router.dismissFullScreenCover()
router.dismissFullScreenCovers(count: 2)
router.dismissFullScreenCovers(to: .onboarding) // dismiss until target
```

## Navigation Interceptors

Interceptors allow you to run middleware-style hooks before navigation happens. Use cases include:
- **Auth guards** - block navigation to protected screens
- **Analytics tracking** - log all navigation events
- **Unsaved changes warnings** - prompt before leaving
- **Feature flags** - conditionally enable/disable routes
- **Rate limiting** - prevent rapid navigation spam

### Basic Usage

```swift
// 1. Implement the NavigationInterceptor protocol
struct AuthInterceptor: NavigationInterceptor {
    func shouldNavigate(from: Destination?, to: Destination) async -> Bool {
        // Check if destination requires authentication
        if case .profile = to {
            let isLoggedIn = await AuthManager.shared.isLoggedIn
            if !isLoggedIn {
                // Block navigation and show login
                return false
            }
        }
        return true // Allow navigation
    }
}

// 2. Add interceptors to router
router.addInterceptor(AuthInterceptor())
router.addInterceptor(AnalyticsInterceptor())

// 3. Use async navigation methods (required for interceptors)
await router.navigateToAsync(.profile(userId: "42"))
```

### Interceptor Execution Order

- Interceptors run in the order they were added
- All interceptors must return `true` for navigation to proceed
- If any interceptor returns `false`, navigation is blocked
- Interceptors run only for `navigateToAsync()` methods (not sync `navigateTo()`)

### Example: Analytics Interceptor

```swift
struct AnalyticsInterceptor: NavigationInterceptor {
    func shouldNavigate(from: Destination?, to: Destination) async -> Bool {
        await Analytics.track(.screenView(to))
        return true // Never blocks navigation
    }
}
```

### Example: Handling Blocked Navigation

```swift
// In your ViewModel/Adapter:
func openProfile() async {
    let success = await router.navigateToAsync(.profile)
    
    if !success {
        // Navigation was blocked by interceptor
        router.presentSheet(.login)
    }
}
```

### Managing Interceptors

```swift
// Add interceptors
router.addInterceptor(AuthInterceptor())
router.addInterceptor(AnalyticsInterceptor())

// Remove all interceptors (useful for testing)
router.removeAllInterceptors()
```

## Example

See `Examples/URLRoutingExample.swift` in the package for a complete demo build.

## MVVM Notes

- ViewModels do not depend on SwiftUI. They call protocol/adapter with `go/present/pop` methods.
- For cross-tab navigation, change `selectedTab` before `navigateTo` into the target stack.

## License

MIT. You may freely use, modify, and embed this package in your projects.
