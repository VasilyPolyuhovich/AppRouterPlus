# Changelog

All notable changes to AppRouterPlus will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-11-30

### Breaking Changes

- **`DestinationType` no longer requires `Codable`**
  - Base protocol is now `Hashable + Sendable` only
  - Deep linking moved to new `DeepLinkableDestination` protocol
  - Migration: Change `DestinationType` -> `DeepLinkableDestination` if you use deep links
  - See [MIGRATION_V2.md](MIGRATION_V2.md) for details

### Added

- New `DeepLinkableDestination` protocol for opt-in deep linking
- Support for non-Codable types in destinations (ViewModels, closures, etc.)
- `Router.navigate(to:)` now requires `DeepLinkableDestination` constraint
- `SimpleNavigationExample.swift` showing internal-only navigation

### Changed

- `URLNavigationHelper.parse()` requires `DeepLinkableDestination`
- `URLNavigationHelper.build()` requires `DeepLinkableDestination`
- `URLRoutingExample.swift` updated to use `DeepLinkableDestination`

### Documentation

- Added `MIGRATION_V2.md` with upgrade paths
- Added `CHANGELOG.md`
- Updated `README.md` with v2.0 changes

### Motivation

- Most apps have 40+ routes but only 5-10 need deep links
- Codable requirement was forcing workarounds for ViewModels
- Clearer separation: Navigation != Deep Linking

---

## [1.0.0] - 2025-11-15

### Initial Release

- Type-safe SwiftUI navigation for iOS 18+
- Per-tab navigation stacks
- Multi-layer sheet management
- Multi-layer full-screen cover management
- Deep link support via Codable destinations
- Navigation interceptors (auth guards, analytics, middleware)
- `@Observable` based router
- MVVM-friendly adapter pattern
