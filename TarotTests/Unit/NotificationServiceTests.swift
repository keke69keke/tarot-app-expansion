// Feature: tarot-iphone-app
// Tests: Property 9 (NotificationService valid hour range)
// Implemented in Task 6.4.

import XCTest
@testable import TarotCore
@testable import TarotNotifications

final class NotificationServiceTests: XCTestCase {
    func testProperty9_validNotificationHoursAreExactlySixThroughTwentyTwo() {
        XCTAssertTrue((6...22).allSatisfy(LocalNotificationService.isValidNotificationHour))
        XCTAssertTrue([0, 5, 23, 24].allSatisfy { !LocalNotificationService.isValidNotificationHour($0) })
    }
}
