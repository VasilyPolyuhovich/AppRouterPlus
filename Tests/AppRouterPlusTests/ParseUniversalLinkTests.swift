import Foundation
import Testing
@testable import AppRouterPlus

@Suite("parseUniversalLink")
struct ParseUniversalLinkTests {

    // MARK: - Happy paths

    @Test("Happy path: scheme + host + path → destinations")
    func happyPath() throws {
        let url = URL(string: "https://example.com/detail?id=123")!
        let result = try #require(URLNavigationHelper.parseUniversalLink(
            url, config: TestConfigs.basic,
            tabType: TestTab.self, destinationType: TestDestination.self
        ))
        #expect(result.tab == nil)
        #expect(result.destinations == [.detail(id: "123")])
    }

    @Test("Happy path with tab query")
    func happyPathWithTab() throws {
        let url = URL(string: "https://example.com/profile?userId=u1&tab=profile")!
        let result = try #require(URLNavigationHelper.parseUniversalLink(
            url, config: TestConfigs.basic,
            tabType: TestTab.self, destinationType: TestDestination.self
        ))
        #expect(result.tab == .profile)
        #expect(result.destinations == [.profile(userId: "u1")])
    }

    @Test("Bare URL (no path) → (tab, [])")
    func barePath() throws {
        let url = URL(string: "https://example.com/?tab=home")!
        let result = try #require(URLNavigationHelper.parseUniversalLink(
            url, config: TestConfigs.basic,
            tabType: TestTab.self, destinationType: TestDestination.self
        ))
        #expect(result.tab == .home)
        #expect(result.destinations.isEmpty)
    }

    // MARK: - Scheme validation

    @Test("Reject scheme not in allowedSchemes")
    func rejectBadScheme() {
        let url = URL(string: "http://example.com/home")!
        let result = URLNavigationHelper.parseUniversalLink(
            url, config: TestConfigs.basic, // https only
            tabType: TestTab.self, destinationType: TestDestination.self
        )
        #expect(result == nil)
    }

    @Test("Accept additional scheme when configured")
    func acceptHttpWhenAllowed() throws {
        let url = URL(string: "http://example.com/home")!
        let result = try #require(URLNavigationHelper.parseUniversalLink(
            url, config: TestConfigs.httpAllowed,
            tabType: TestTab.self, destinationType: TestDestination.self
        ))
        #expect(result.destinations == [.home])
    }

    @Test("Scheme comparison is case-insensitive")
    func schemeCaseInsensitive() throws {
        let url = URL(string: "HTTPS://example.com/home")!
        let result = try #require(URLNavigationHelper.parseUniversalLink(
            url, config: TestConfigs.basic,
            tabType: TestTab.self, destinationType: TestDestination.self
        ))
        #expect(result.destinations == [.home])
    }

    // MARK: - Host validation

    @Test("Reject host not in allowedHosts")
    func rejectBadHost() {
        let url = URL(string: "https://malicious.com/home")!
        let result = URLNavigationHelper.parseUniversalLink(
            url, config: TestConfigs.basic,
            tabType: TestTab.self, destinationType: TestDestination.self
        )
        #expect(result == nil)
    }

    @Test("Host comparison is case-insensitive")
    func hostCaseInsensitive() throws {
        let url = URL(string: "https://EXAMPLE.com/home")!
        let result = try #require(URLNavigationHelper.parseUniversalLink(
            url, config: TestConfigs.basic,
            tabType: TestTab.self, destinationType: TestDestination.self
        ))
        #expect(result.destinations == [.home])
    }

    @Test("Multiple hosts: any one matches")
    func multipleHosts() throws {
        let url1 = URL(string: "https://example.com/home")!
        let url2 = URL(string: "https://example.org/home")!
        let r1 = URLNavigationHelper.parseUniversalLink(
            url1, config: TestConfigs.multiHost,
            tabType: TestTab.self, destinationType: TestDestination.self
        )
        let r2 = URLNavigationHelper.parseUniversalLink(
            url2, config: TestConfigs.multiHost,
            tabType: TestTab.self, destinationType: TestDestination.self
        )
        #expect(r1 != nil)
        #expect(r2 != nil)
    }

    // MARK: - pathPrefix validation (per-segment)

    @Test("pathPrefix bare match: path == prefix")
    func prefixBareMatch() throws {
        let url = URL(string: "https://example.com/app?tab=home")!
        let result = try #require(URLNavigationHelper.parseUniversalLink(
            url, config: TestConfigs.withPrefix,
            tabType: TestTab.self, destinationType: TestDestination.self
        ))
        #expect(result.destinations.isEmpty)
    }

    @Test("pathPrefix per-segment match")
    func prefixPerSegmentMatch() throws {
        let url = URL(string: "https://example.com/app/home")!
        let result = try #require(URLNavigationHelper.parseUniversalLink(
            url, config: TestConfigs.withPrefix,
            tabType: TestTab.self, destinationType: TestDestination.self
        ))
        #expect(result.destinations == [.home])
    }

    @Test("pathPrefix rejects lexical false-positive /appstore")
    func prefixRejectsLexical() {
        let url = URL(string: "https://example.com/appstore/foo")!
        let result = URLNavigationHelper.parseUniversalLink(
            url, config: TestConfigs.withPrefix,
            tabType: TestTab.self, destinationType: TestDestination.self
        )
        #expect(result == nil)
    }

    @Test("pathPrefix rejects /application")
    func prefixRejectsAdjacent() {
        let url = URL(string: "https://example.com/application/foo")!
        let result = URLNavigationHelper.parseUniversalLink(
            url, config: TestConfigs.withPrefix,
            tabType: TestTab.self, destinationType: TestDestination.self
        )
        #expect(result == nil)
    }

    @Test("pathPrefix accepts trailing slash on URL: /app/")
    func prefixAcceptsTrailingSlashInUrl() throws {
        let url = URL(string: "https://example.com/app/?tab=home")!
        let result = try #require(URLNavigationHelper.parseUniversalLink(
            url, config: TestConfigs.withPrefix,
            tabType: TestTab.self, destinationType: TestDestination.self
        ))
        #expect(result.destinations.isEmpty)
        #expect(result.tab == .home)
    }

    @Test("Missing prefix not required when config has none")
    func noPrefix() throws {
        let url = URL(string: "https://example.com/home")!
        let result = try #require(URLNavigationHelper.parseUniversalLink(
            url, config: TestConfigs.basic,
            tabType: TestTab.self, destinationType: TestDestination.self
        ))
        #expect(result.destinations == [.home])
    }

    // MARK: - tab resolution

    @Test("Multi-value tab query: LAST wins")
    func tabLastWins() throws {
        let url = URL(string: "https://example.com/home?tab=home&tab=profile")!
        let result = try #require(URLNavigationHelper.parseUniversalLink(
            url, config: TestConfigs.basic,
            tabType: TestTab.self, destinationType: TestDestination.self
        ))
        #expect(result.tab == .profile)
    }

    @Test("Unknown tab value → tab nil")
    func unknownTab() throws {
        let url = URL(string: "https://example.com/home?tab=nonexistent")!
        let result = try #require(URLNavigationHelper.parseUniversalLink(
            url, config: TestConfigs.basic,
            tabType: TestTab.self, destinationType: TestDestination.self
        ))
        #expect(result.tab == nil)
    }

    // MARK: - Destination mapping

    @Test("Unmapped segment → nil")
    func unmappedSegment() {
        let url = URL(string: "https://example.com/unknown")!
        let result = URLNavigationHelper.parseUniversalLink(
            url, config: TestConfigs.basic,
            tabType: TestTab.self, destinationType: TestDestination.self
        )
        #expect(result == nil)
    }

    @Test("Missing required query param → nil")
    func missingRequiredParam() {
        // .detail requires ?id=
        let url = URL(string: "https://example.com/detail")!
        let result = URLNavigationHelper.parseUniversalLink(
            url, config: TestConfigs.basic,
            tabType: TestTab.self, destinationType: TestDestination.self
        )
        #expect(result == nil)
    }

    // MARK: - Inline (non-config) overload

    @Test("Inline overload mirrors config overload")
    func inlineOverload() throws {
        let url = URL(string: "https://example.com/home")!
        let result = try #require(URLNavigationHelper.parseUniversalLink(
            url,
            allowedHosts: ["example.com"],
            tabType: TestTab.self,
            destinationType: TestDestination.self
        ))
        #expect(result.destinations == [.home])
    }
}
