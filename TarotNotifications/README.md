# TarotNotifications

This module contains `LocalNotificationService`, the concrete implementation of
`NotificationService` from `TarotCore`.

It uses `UNUserNotificationCenter` with `UNCalendarNotificationTrigger` to schedule
a daily repeating notification at the user-configured hour (6 … 22).

> Implemented in Task 6 of the implementation plan.
