import Testing
@testable import AppRouterPlus

@Suite("UniversalLinkConfig")
struct UniversalLinkConfigTests {

    @Test("Default scheme is https")
    func defaultScheme() {
        let config = UniversalLinkConfig(allowedHosts: ["example.com"])
        #expect(config.allowedSchemes == ["https"])
    }

    @Test("Hosts normalized to lowercase")
    func hostsLowercased() {
        let config = UniversalLinkConfig(allowedHosts: ["Example.COM", "Foo.BAR"])
        #expect(config.allowedHosts == ["example.com", "foo.bar"])
    }

    @Test("Schemes normalized to lowercase")
    func schemesLowercased() {
        let config = UniversalLinkConfig(
            allowedHosts: ["example.com"],
            allowedSchemes: ["HTTPS", "Http"]
        )
        #expect(config.allowedSchemes == ["https", "http"])
    }

    @Test("Trailing slash in pathPrefix stripped")
    func trailingSlashStripped() {
        let config = UniversalLinkConfig(allowedHosts: ["example.com"], pathPrefix: "/app/")
        #expect(config.pathPrefix == "/app")
    }

    @Test("Multiple trailing slashes stripped")
    func multipleTrailingSlashesStripped() {
        let config = UniversalLinkConfig(allowedHosts: ["example.com"], pathPrefix: "/app///")
        #expect(config.pathPrefix == "/app")
    }

    @Test("Single slash pathPrefix preserved")
    func singleSlashPreserved() {
        let config = UniversalLinkConfig(allowedHosts: ["example.com"], pathPrefix: "/")
        #expect(config.pathPrefix == "/")
    }

    @Test("Nil pathPrefix preserved")
    func nilPrefixPreserved() {
        let config = UniversalLinkConfig(allowedHosts: ["example.com"])
        #expect(config.pathPrefix == nil)
    }

    @Test("Empty hosts accepted (will fail validation at parse time)")
    func emptyHostsAccepted() {
        let config = UniversalLinkConfig(allowedHosts: [])
        #expect(config.allowedHosts.isEmpty)
    }

    @Test("Hashable: same params == same hash")
    func hashable() {
        let a = UniversalLinkConfig(allowedHosts: ["example.com"], pathPrefix: "/app")
        let b = UniversalLinkConfig(allowedHosts: ["example.com"], pathPrefix: "/app")
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }

    @Test("Hashable: different prefix → different value")
    func hashableInequality() {
        let a = UniversalLinkConfig(allowedHosts: ["example.com"], pathPrefix: "/app")
        let b = UniversalLinkConfig(allowedHosts: ["example.com"], pathPrefix: "/p")
        #expect(a != b)
    }
}
