import Foundation
import UserNotifications
import SwiftUI

// MARK: - Notification Permission Manager

/// Manages notification permissions with parental gate integration
@MainActor
public final class NotificationPermissionManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published public private(set) var isRequestInProgress = false
    @Published public var shouldShowParentGate = false
    
    // MARK: - Private Properties
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // MARK: - Initialization
    
    public init() {
        Task {
            await checkCurrentStatus()
        }
    }
    
    // MARK: - Permission Management
    
    /// Request notification permissions with parent gate protection
    public func requestPermissions() async throws {
        // Check if parent gate is required
        if !ParentGateManager.isRecentlyPassed(for: .notifications, within: 300) {
            // Show parent gate first
            shouldShowParentGate = true
            return
        }
        
        await performPermissionRequest()
    }
    
    /// Perform the actual permission request (called after parent gate success)
    public func performPermissionRequest() async {
        isRequestInProgress = true
        defer { isRequestInProgress = false }
        
        do {
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            let granted = try await notificationCenter.requestAuthorization(options: options)
            
            await checkCurrentStatus()
            
            #if DEBUG
            print("NotificationPermissionManager: Permission granted: \(granted)")
            #endif
            
            // TODO: Track analytics
            // Analytics.track("notification_permission_requested", properties: [
            //     "granted": granted,
            //     "timestamp": Date().timeIntervalSince1970
            // ])
            
        } catch {
            #if DEBUG
            print("NotificationPermissionManager: Error requesting permissions: \(error)")
            #endif
            
            // TODO: Track error
            // Analytics.track("notification_permission_error", properties: [
            //     "error": error.localizedDescription
            // ])
        }
    }
    
    /// Check current authorization status
    public func checkCurrentStatus() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        
        #if DEBUG
        print("NotificationPermissionManager: Current status: \(authorizationStatus.description)")
        #endif
    }
    
    /// Open app settings for notification permissions
    public func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
        
        // TODO: Track analytics
        // Analytics.track("notification_settings_opened")
    }
    
    // MARK: - Parent Gate Integration
    
    /// Handle parent gate success for notifications
    public func handleParentGateSuccess() {
        shouldShowParentGate = false
        
        Task {
            await performPermissionRequest()
        }
    }
    
    /// Handle parent gate cancellation
    public func handleParentGateCancel() {
        shouldShowParentGate = false
    }
    
    // MARK: - Computed Properties
    
    /// Whether notifications are enabled
    public var isEnabled: Bool {
        return authorizationStatus == .authorized
    }
    
    /// Whether we can request permissions
    public var canRequestPermissions: Bool {
        return authorizationStatus == .notDetermined
    }
    
    /// Whether user needs to go to settings
    public var needsSettingsAccess: Bool {
        return authorizationStatus == .denied
    }
    
    /// User-friendly status message
    public var statusMessage: String {
        switch authorizationStatus {
        case .notDetermined:
            return NSLocalizedString("Notifications.Status.NotDetermined", value: "Tap to enable sleep reminders", comment: "")
        case .denied:
            return NSLocalizedString("Notifications.Status.Denied", value: "Enable in Settings to receive reminders", comment: "")
        case .authorized:
            return NSLocalizedString("Notifications.Status.Authorized", value: "Sleep reminders enabled", comment: "")
        case .provisional:
            return NSLocalizedString("Notifications.Status.Provisional", value: "Quiet notifications enabled", comment: "")
        case .ephemeral:
            return NSLocalizedString("Notifications.Status.Ephemeral", value: "Temporary notifications enabled", comment: "")
        @unknown default:
            return NSLocalizedString("Notifications.Status.Unknown", value: "Unknown notification status", comment: "")
        }
    }
    
    /// Status color for UI
    public var statusColor: Color {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        @unknown default:
            return .gray
        }
    }
    
    /// Status icon for UI
    public var statusIcon: String {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return "bell.fill"
        case .denied:
            return "bell.slash.fill"
        case .notDetermined:
            return "bell"
        @unknown default:
            return "bell.badge.question"
        }
    }
}

// MARK: - UNAuthorizationStatus Extension

extension UNAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined:
            return "notDetermined"
        case .denied:
            return "denied"
        case .authorized:
            return "authorized"
        case .provisional:
            return "provisional"
        case .ephemeral:
            return "ephemeral"
        @unknown default:
            return "unknown"
        }
    }
}

// MARK: - Notification Settings View

/// SwiftUI view for managing notification settings with parent gate
public struct NotificationSettingsView: View {
    @StateObject private var permissionManager = NotificationPermissionManager()
    @State private var showParentGate = false
    
    public var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    Image(systemName: permissionManager.statusIcon)
                        .font(.title2)
                        .foregroundColor(permissionManager.statusColor)
                        .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sleep Reminders")
                            .font(.headline)
                        
                        Text(permissionManager.statusMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if permissionManager.canRequestPermissions {
                        Button("Enable") {
                            Task {
                                try? await permissionManager.requestPermissions()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(permissionManager.isRequestInProgress)
                        
                    } else if permissionManager.needsSettingsAccess {
                        Button("Settings") {
                            permissionManager.openAppSettings()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Notifications")
            } footer: {
                Text("Get gentle reminders for bedtime routines and sleep schedules. Notifications require parental approval.")
                    .font(.caption)
            }
            
            if permissionManager.isEnabled {
                Section("Notification Types") {
                    NotificationTypeRow(
                        title: "Bedtime Reminders",
                        description: "Daily reminders for sleep routines",
                        icon: "moon.zzz",
                        isEnabled: true
                    )
                    
                    NotificationTypeRow(
                        title: "Schedule Alerts",
                        description: "When sleep schedules are active",
                        icon: "calendar.badge.clock",
                        isEnabled: true
                    )
                    
                    NotificationTypeRow(
                        title: "Sound Timer",
                        description: "When sleep timer completes",
                        icon: "timer",
                        isEnabled: false
                    )
                }
            }
            
            Section("Privacy & Safety") {
                HStack {
                    Image(systemName: "shield.checkered")
                        .foregroundColor(.blue)
                    Text("Parental approval required for notification changes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "lock.shield")
                        .foregroundColor(.green)
                    Text("No personal data collected or shared")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Notifications")
        .sheet(isPresented: $showParentGate) {
            ParentGateView(
                isPresented: $showParentGate,
                context: .notifications,
                onSuccess: {
                    permissionManager.handleParentGateSuccess()
                }
            )
        }
        .onReceive(permissionManager.$shouldShowParentGate) { shouldShow in
            showParentGate = shouldShow
        }
        .task {
            await permissionManager.checkCurrentStatus()
        }
    }
}

// MARK: - Notification Type Row

struct NotificationTypeRow: View {
    let title: String
    let description: String
    let icon: String
    let isEnabled: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isEnabled ? .blue : .gray)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(isEnabled ? .primary : .secondary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isEnabled {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
} 