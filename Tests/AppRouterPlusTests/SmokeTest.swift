import Testing
@testable import AppRouterPlus

@Suite("Smoke")
struct SmokeTests {

    @Test("Test target compiles and runs")
    func smoke() {
        #expect(TestTab.allCases.count == 2)
    }
}
