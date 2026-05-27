import Foundation
@testable import AppRouterPlus

// MARK: - Tabs

enum TestTab: String, TabType, CaseIterable {
    case home, profile
}

// MARK: - Destinations (single-segment style — works with library's per-segment parse loop)

enum TestDestination: DeepLinkableDestination {
    case home
    case detail(id: String)
    case profile(userId: String)

    static func path(for destination: TestDestination) -> String {
        switch destination {
        case .home: return "home"
        case .detail: return "detail"
        case .profile: return "profile"
        }
    }

    static func from(path: String, fullPath: [String], parameters: [String: [String]]) -> TestDestination? {
        switch path {
        case "home":
            return .home
        case "detail":
            guard let id = parameters["id"]?.last else { return nil }
            return .detail(id: id)
        case "profile":
            guard let uid = parameters["userId"]?.last else { return nil }
            return .profile(userId: uid)
        default:
            return nil
        }
    }
}

// MARK: - Sheets

enum TestSheet: String, SheetType {
    case settings
    var id: String { rawValue }
}

// MARK: - Configs

enum TestConfigs {
    static let basic = UniversalLinkConfig(allowedHosts: ["example.com"])
    static let withPrefix = UniversalLinkConfig(allowedHosts: ["example.com"], pathPrefix: "/app")
    static let multiHost = UniversalLinkConfig(allowedHosts: ["example.com", "example.org"])
    static let httpAllowed = UniversalLinkConfig(allowedHosts: ["example.com"], allowedSchemes: ["https", "http"])
}
