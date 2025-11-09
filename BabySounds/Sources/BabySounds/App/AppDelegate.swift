import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_: UIApplication,
                     didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool
    {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self

        return true
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Handle notification when app is in foreground
    func userNotificationCenter(_: UNUserNotificationCenter,
                                willPresent _: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions)
                                    -> Void)
    {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    /// Handle notification tap
    func userNotificationCenter(_: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void)
    {
        let userInfo = response.notification.request.content.userInfo

        // Check if this is a bedtime notification
        if let type = userInfo["type"] as? String,
           type == "bedtime",
           let scheduleId = userInfo["scheduleId"] as? String,
           let selectedSounds = userInfo["selectedSounds"] as? [String]
        {
            // Handle bedtime notification on main thread
            Task { @MainActor in
                SleepScheduleManager.shared.handleBedtimeNotification(
                    scheduleId: scheduleId,
                    selectedSounds: selectedSounds
                )
            }
        }

        completionHandler()
    }
}
