import SwiftUI

// MARK: - Safe Link Wrapper

/// Wraps external links with parental gate protection
public struct SafeLinkWrapper: View {
    let url: URL
    let title: String
    let icon: String?
    
    @State private var showParentGate = false
    
    public init(url: URL, title: String, icon: String? = nil) {
        self.url = url
        self.title = title
        self.icon = icon
    }
    
    public var body: some View {
        Button(action: {
            handleLinkTap()
        }) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(.blue)
                }
                
                Text(title)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Image(systemName: "arrow.up.right.square")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showParentGate) {
            ParentGateView(
                isPresented: $showParentGate,
                context: .externalLink
            )                {
                    openExternalLink()
                }
        }
    }
    
    private func handleLinkTap() {
        if ParentGateManager.isRecentlyPassed(for: .externalLink, within: 300) {
            // Recently passed, open directly
            openExternalLink()
        } else {
            // Show parent gate
            showParentGate = true
        }
    }
    
    private func openExternalLink() {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            
            #if DEBUG
            print("SafeLinkWrapper: Opening external URL: \(url)")
            #endif
            
            // TODO: Track analytics
            // Analytics.track("external_link_opened", properties: [
            //     "url": url.absoluteString,
            //     "title": title
            // ])
        }
    }
}

// MARK: - Safe Link Button

/// Button variant of SafeLinkWrapper
public struct SafeLinkButton: View {
    let url: URL
    let title: String
    let style: ButtonStyle
    
    @State private var showParentGate = false
    
    public enum ButtonStyle {
        case primary
        case secondary
        case destructive
        
        var color: Color {
            switch self {
            case .primary:
                return .blue

            case .secondary:
                return .gray

            case .destructive:
                return .red
            }
        }
    }
    
    public init(url: URL, title: String, style: ButtonStyle = .primary) {
        self.url = url
        self.title = title
        self.style = style
    }
    
    public var body: some View {
        Button(action: {
            handleLinkTap()
        }) {
            HStack {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                
                Image(systemName: "arrow.up.right.square")
                    .font(.caption)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(style.color)
            .cornerRadius(12)
        }
        .sheet(isPresented: $showParentGate) {
            ParentGateView(
                isPresented: $showParentGate,
                context: .externalLink
            )                {
                    openExternalLink()
                }
        }
    }
    
    private func handleLinkTap() {
        if ParentGateManager.isRecentlyPassed(for: .externalLink, within: 300) {
            openExternalLink()
        } else {
            showParentGate = true
        }
    }
    
    private func openExternalLink() {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Enhanced Help View

/// Updated HelpView with safe external links and parent gate integration
public struct EnhancedHelpView: View {
    public var body: some View {
        List {
            Section("Getting Started") {
                HelpRow(
                    icon: "play.circle",
                    title: "How to play sounds",
                    description: "Tap any sound card to start playing calming baby sounds"
                )
                
                HelpRow(
                    icon: "heart.circle",
                    title: "Creating favorites",
                    description: "Tap the heart icon to save your favorite sounds for quick access"
                )
                
                HelpRow(
                    icon: "timer",
                    title: "Setting sleep timer",
                    description: "Use the timer to automatically stop sounds after a set duration"
                )
            }
            
            Section("Premium Features") {
                HelpRow(
                    icon: "crown.fill",
                    title: "Premium sounds",
                    description: "Access 50+ exclusive high-quality sounds with Premium subscription"
                )
                
                HelpRow(
                    icon: "slider.horizontal.3",
                    title: "Multi-track mixing",
                    description: "Play up to 4 sounds simultaneously to create custom soundscapes"
                )
                
                HelpRow(
                    icon: "calendar",
                    title: "Sleep schedules",
                    description: "Set automated bedtime routines with your favorite sounds"
                )
            }
            
            Section("Child Safety") {
                HelpRow(
                    icon: "shield.checkered",
                    title: "Parental controls",
                    description: "All settings and purchases require parental verification"
                )
                
                HelpRow(
                    icon: "volume.2",
                    title: "Safe volume limits",
                    description: "Automatic volume limiting protects young ears from loud sounds"
                )
                
                HelpRow(
                    icon: "moon.zzz",
                    title: "Sleep-focused design",
                    description: "Designed specifically for bedtime and nap routines"
                )
            }
            
            Section("Support & Feedback") {
                SafeLinkWrapper(
                    url: URL(string: "mailto:support@babysounds.app?subject=Baby%20Sounds%20Support")!,
                    title: "Contact Support",
                    icon: "envelope"
                )
                
                SafeLinkWrapper(
                    url: URL(string: "https://babysounds.app/feedback")!,
                    title: "Send Feedback",
                    icon: "bubble.left.and.bubble.right"
                )
                
                SafeLinkWrapper(
                    url: URL(string: "https://apps.apple.com/app/baby-sounds/id123456789?action=write-review")!,
                    title: "Rate on App Store",
                    icon: "star"
                )
            }
            
            Section("Legal & Privacy") {
                SafeLinkWrapper(
                    url: URL(string: "https://babysounds.app/privacy")!,
                    title: "Privacy Policy",
                    icon: "hand.raised"
                )
                
                SafeLinkWrapper(
                    url: URL(string: "https://babysounds.app/terms")!,
                    title: "Terms of Service",
                    icon: "doc.text"
                )
                
                SafeLinkWrapper(
                    url: URL(string: "https://babysounds.app/coppa")!,
                    title: "COPPA Compliance",
                    icon: "shield.checkerboard"
                )
            }
            
            Section("App Information") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(appVersion)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Build")
                    Spacer()
                    Text(buildNumber)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Help & FAQ")
    }
    
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    }
    
    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
    }
}

// MARK: - Help Row

struct HelpRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        EnhancedHelpView()
    }
}
