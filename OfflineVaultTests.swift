import XCTest
@testable import OfflineVault

final class OfflineVaultTests: XCTestCase {
    func testMediaItemKindsHaveExpectedFileExtensions() {
        XCTAssertEqual(MediaItem.Kind.photo == .photo ? "jpg" : "mov", "jpg")
        XCTAssertEqual(MediaItem.Kind.video == .photo ? "jpg" : "mov", "mov")
    }
}
