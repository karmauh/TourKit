import Testing

@testable import TourKit

@Suite("Package")
struct PackageTests {
    @Test("Library module is importable")
    func moduleIsImportable() {
        #expect(!PackageInfo.version.isEmpty)
    }
}
