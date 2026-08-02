import Foundation

/// Wrapper around `UNUserNotificationCenter` for daily card reminders (Requirement 4.6).
public protocol NotificationService {

    /// Requests the user's permission to show notifications.
    ///
    /// - Returns: `true` when permission was granted.
    func requestPermission() async -> Bool

    /// Schedules a repeating daily notification at `hour` (24-hour clock).
    ///
    /// `hour` must be in the range 6 … 22; values outside this range must cause
    /// `TarotError.validationFailed` to be thrown (Requirement 4.6).
    /// Replaces any previously scheduled daily notification.
    ///
    /// - Throws: `TarotError.validationFailed` for out-of-range `hour`.
    ///           `TarotError.notificationPermissionDenied` when permission has not been granted.
    func scheduleDailyNotification(hour: Int) async throws

    /// Cancels any pending daily notification.
    func cancelDailyNotification() async
}
