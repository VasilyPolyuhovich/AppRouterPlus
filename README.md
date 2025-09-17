# AppRouterPlus

A simple router for SwiftUI iOS 18+ with support for:
- stacks for each tab (`NavigationStack`),
- deeplinks with **stable** segments,
- navigation policies (`replace`, `append`, `replaceTop`),
- multi-layer `sheet` stack,
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
.onOpenURL { url in _ = router.navigate(to: url) } // deeplink
```

3) Inject a thin adapter into the VM:

```swift
@MainActor final class RouterAdapter {
  private let router: Router<AppTab, Destination, Sheet>
  init(_ router: Router<AppTab, Destination, Sheet>) { self.router = router }

  func showDetail(_ id: String) { router.navigateTo(.detail(id: id), policy: .append) }
  func showSettings() { _ = router.presentSheet(.settings) }
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

## Example

See `Examples/URLRoutingExample.swift` in the package for a complete demo build.

## MVVM Notes

- ViewModels do not depend on SwiftUI. They call protocol/adapter with `go/present/pop` methods.
- For cross-tab navigation, change `selectedTab` before `navigateTo` into the target stack.

## License

MIT. You may freely use, modify, and embed this package in your projects.
