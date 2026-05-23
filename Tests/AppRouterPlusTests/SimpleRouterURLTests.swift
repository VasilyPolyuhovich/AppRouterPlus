import Foundation
import Testing
@testable import AppRouterPlus

@Suite("SimpleRouter + URLs")
@MainActor
struct SimpleRouterURLTests {

    func makeRouter() -> SimpleRouter<TestDestination, TestSheet> {
        SimpleRouter()
    }

    // MARK: - Custom-scheme deeplink

    @Test("Custom scheme: valid URL navigates")
    func customSchemeValid() {
        let router = makeRouter()
        let url = URL(string: "myapp://home")!
        let ok = router.navigate(to: url)
        #expect(ok == true)
        #expect(router.path == [.home])
    }

    @Test("Custom scheme: unmapped → false")
    func customSchemeInvalid() {
        let router = makeRouter()
        let url = URL(string: "myapp://nonexistent")!
        let ok = router.navigate(to: url)
        #expect(ok == false)
        #expect(router.path.isEmpty)
    }

    @Test("Custom scheme: tab query ignored (SimpleRouter has no tabs)")
    func customSchemeIgnoresTab() {
        let router = makeRouter()
        let url = URL(string: "myapp://home?tab=anything")!
        let ok = router.navigate(to: url)
        #expect(ok == true)
        #expect(router.path == [.home])
    }
}
