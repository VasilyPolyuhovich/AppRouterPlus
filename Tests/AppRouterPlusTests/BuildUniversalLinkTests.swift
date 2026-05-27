import Foundation
import Testing
@testable import AppRouterPlus

@Suite("buildUniversalLink")
struct BuildUniversalLinkTests {

    @Test("Happy path: host + destination")
    func happyPath() throws {
        let url = try #require(URLNavigationHelper.buildUniversalLink(
            host: "example.com",
            destinations: [TestDestination.home]
        ))
        #expect(url.absoluteString == "https://example.com/home")
    }

    @Test("With tab")
    func withTab() throws {
        let url = try #require(URLNavigationHelper.buildUniversalLink(
            host: "example.com",
            tab: TestTab.profile,
            destinations: [TestDestination.home]
        ))
        #expect(url.absoluteString == "https://example.com/home?tab=profile")
    }

    @Test("With extraQuery")
    func withExtraQuery() throws {
        let url = try #require(URLNavigationHelper.buildUniversalLink(
            host: "example.com",
            destinations: [TestDestination.detail(id: "123")],
            extraQuery: ["id": "123"]
        ))
        #expect(url.absoluteString == "https://example.com/detail?id=123")
    }

    @Test("With pathPrefix")
    func withPathPrefix() throws {
        let url = try #require(URLNavigationHelper.buildUniversalLink(
            host: "example.com",
            pathPrefix: "/app",
            destinations: [TestDestination.home]
        ))
        #expect(url.absoluteString == "https://example.com/app/home")
    }

    @Test("Trailing slash in pathPrefix normalized")
    func trailingSlashNormalized() throws {
        let url = try #require(URLNavigationHelper.buildUniversalLink(
            host: "example.com",
            pathPrefix: "/app/",
            destinations: [TestDestination.home]
        ))
        #expect(url.absoluteString == "https://example.com/app/home")
    }

    @Test("Custom scheme")
    func customScheme() throws {
        let url = try #require(URLNavigationHelper.buildUniversalLink(
            host: "example.com",
            scheme: "http",
            destinations: [TestDestination.home]
        ))
        #expect(url.absoluteString == "http://example.com/home")
    }

    @Test("Empty destinations + tab → root path")
    func emptyDestinations() throws {
        let url = try #require(URLNavigationHelper.buildUniversalLink(
            host: "example.com",
            tab: TestTab.home,
            destinations: [TestDestination]()
        ))
        #expect(url.absoluteString == "https://example.com/?tab=home")
    }

    @Test("Multiple destinations join with /")
    func multipleDestinations() throws {
        let url = try #require(URLNavigationHelper.buildUniversalLink(
            host: "example.com",
            destinations: [TestDestination.home, TestDestination.detail(id: "123")],
            extraQuery: ["id": "123"]
        ))
        #expect(url.absoluteString == "https://example.com/home/detail?id=123")
    }

    @Test("Round-trip: build → parse → original tab+destinations")
    func roundTrip() throws {
        let original = TestDestination.profile(userId: "u42")
        let url = try #require(URLNavigationHelper.buildUniversalLink(
            host: "example.com",
            tab: TestTab.profile,
            destinations: [original],
            extraQuery: ["userId": "u42"]
        ))
        let parsed = try #require(URLNavigationHelper.parseUniversalLink(
            url, config: TestConfigs.basic,
            tabType: TestTab.self, destinationType: TestDestination.self
        ))
        #expect(parsed.tab == .profile)
        #expect(parsed.destinations == [original])
    }
}
