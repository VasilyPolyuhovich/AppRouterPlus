import Foundation
import Testing
@testable import AppRouterPlus

@Suite("Router + Universal Links")
@MainActor
struct RouterUniversalLinkTests {

    func makeRouter() -> Router<TestTab, TestDestination, TestSheet> {
        Router(initialTab: .home)
    }

    // MARK: - Inline overload

    @Test("Inline: invalid URL returns false")
    func inlineInvalid() {
        let router = makeRouter()
        let url = URL(string: "https://other.com/home")!
        let ok = router.navigate(
            toUniversalLink: url,
            allowedHosts: ["example.com"]
        )
        #expect(ok == false)
    }

    @Test("Inline: valid URL navigates and returns true")
    func inlineValid() {
        let router = makeRouter()
        let url = URL(string: "https://example.com/home?tab=profile")!
        let ok = router.navigate(
            toUniversalLink: url,
            allowedHosts: ["example.com"],
            deepPush: false // synchronous path for assertion
        )
        #expect(ok == true)
        #expect(router.selectedTab == .profile)
        #expect(router[pathFor: .profile] == [.home])
    }

    // MARK: - Config overload

    @Test("Config: valid URL navigates")
    func configValid() {
        let router = makeRouter()
        let url = URL(string: "https://example.com/home")!
        let ok = router.navigate(
            toUniversalLink: url,
            config: TestConfigs.basic,
            deepPush: false
        )
        #expect(ok == true)
        #expect(router[pathFor: .home] == [.home])
    }

    // MARK: - deepPush behavior

    @Test("deepPush true + policy .replace → async navigation, returns true immediately")
    func deepPushAsync() async {
        let router = makeRouter()
        let url = URL(string: "https://example.com/home")!
        let ok = router.navigate(
            toUniversalLink: url,
            config: TestConfigs.basic,
            policy: .replace,
            deepPush: true
        )
        #expect(ok == true)
        // Wait for background Task to push first destination (15ms step in deepPushTo)
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        #expect(router[pathFor: .home] == [.home])
    }

    @Test("deepPush true + policy .append → ignored, synchronous navigation")
    func deepPushIgnoredWithAppend() {
        let router = makeRouter()
        let url = URL(string: "https://example.com/home")!
        let ok = router.navigate(
            toUniversalLink: url,
            config: TestConfigs.basic,
            policy: .append,
            deepPush: true // ignored
        )
        #expect(ok == true)
        #expect(router[pathFor: .home] == [.home]) // immediate, no async
    }

    // MARK: - handleUserActivity

    @Test("handleUserActivity: BrowseWeb + webpageURL → navigates")
    func handleBrowseWeb() {
        let router = makeRouter()
        let activity = NSUserActivity(activityType: AppRouterBrowseWebActivityType)
        activity.webpageURL = URL(string: "https://example.com/home?tab=home")
        let ok = router.handleUserActivity(
            activity, config: TestConfigs.basic, deepPush: false
        )
        #expect(ok == true)
        #expect(router[pathFor: .home] == [.home])
    }

    @Test("handleUserActivity: non-BrowseWeb activity → false")
    func handleNonBrowseWeb() {
        let router = makeRouter()
        let activity = NSUserActivity(activityType: "com.example.other")
        activity.webpageURL = URL(string: "https://example.com/home")
        let ok = router.handleUserActivity(
            activity, config: TestConfigs.basic, deepPush: false
        )
        #expect(ok == false)
    }

    @Test("handleUserActivity: nil webpageURL → false")
    func handleNoURL() {
        let router = makeRouter()
        let activity = NSUserActivity(activityType: AppRouterBrowseWebActivityType)
        // webpageURL not set
        let ok = router.handleUserActivity(
            activity, config: TestConfigs.basic, deepPush: false
        )
        #expect(ok == false)
    }
}
