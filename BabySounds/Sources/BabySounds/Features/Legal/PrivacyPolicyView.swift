import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    privacyPolicyContent
                }
                .padding()
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var privacyPolicyContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Last Updated: November 2, 2025")
                .font(.caption)
                .foregroundColor(.secondary)

            Group {
                sectionTitle("Our Commitment to Children's Privacy")
                sectionText(
                    "Baby Sounds is designed specifically for babies and young children. We take children's privacy extremely seriously and comply with the Children's Online Privacy Protection Act (COPPA), GDPR, and CCPA."
                )

                sectionTitle("Information We Collect")
                sectionText("**We do not knowingly collect personal information from children under 13.**")
                bulletPoint("Anonymous usage statistics (crash reports, feature usage)")
                bulletPoint("Device information (iOS version, device model)")
                bulletPoint("Purchase information (handled securely by Apple)")
                bulletPoint("Audio session data (not recorded or transmitted)")

                sectionTitle("How We Use Information")
                sectionText("Information is used solely to:")
                bulletPoint("Improve app functionality and stability")
                bulletPoint("Process in-app purchases")
                bulletPoint("Ensure WHO hearing safety compliance")
                bulletPoint("Provide customer support")

                sectionTitle("Data Storage and Security")
                bulletPoint("All data stored locally on device")
                bulletPoint("No user accounts or registration required")
                bulletPoint("No data sold or shared with third parties")
                bulletPoint("Purchase data handled exclusively by Apple")
            }

            Group {
                sectionTitle("WHO Hearing Safety")
                sectionText("Baby Sounds implements World Health Organization guidelines:")
                bulletPoint("Volume monitoring and limits")
                bulletPoint("Listening time tracking")
                bulletPoint("Automatic safety warnings")
                bulletPoint("Parent gate for settings")

                sectionTitle("Parental Controls")
                sectionText("Parents have full control over:")
                bulletPoint("Volume limits and safety settings")
                bulletPoint("All purchase decisions (Apple Family Sharing)")
                bulletPoint("Data deletion (uninstalling app removes all data)")
                bulletPoint("Access to premium features")

                sectionTitle("Your Rights (GDPR/CCPA)")
                bulletPoint("**Access**: Request information we hold")
                bulletPoint("**Deletion**: Uninstall app to remove all data")
                bulletPoint("**Portability**: Export favorites and settings")
                bulletPoint("**Opt-out**: Disable analytics in Settings")

                sectionTitle("Third-Party Services")
                sectionText("Baby Sounds uses:")
                bulletPoint("Apple StoreKit 2 for purchases")
                bulletPoint("Apple CloudKit for backup (optional)")
                bulletPoint("Apple Analytics (can be disabled)")
                sectionText("All third-party services comply with children's privacy laws.")
            }

            Group {
                sectionTitle("Changes to Privacy Policy")
                sectionText(
                    "We will notify users of material changes via in-app notification. Continued use constitutes acceptance of changes."
                )

                sectionTitle("Contact Us")
                sectionText("Questions about privacy:")
                bulletPoint("Email: privacy@babysounds.app")
                bulletPoint("GitHub: github.com/vpavlov-me/BabySounds")

                sectionTitle("Compliance Certifications")
                bulletPoint("COPPA Compliant (Children's Online Privacy Protection)")
                bulletPoint("GDPR Compliant (EU General Data Protection Regulation)")
                bulletPoint("CCPA Compliant (California Consumer Privacy Act)")
                bulletPoint("WHO Hearing Safety Guidelines")
            }

            Text("© 2025 Baby Sounds. All rights reserved.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .padding(.top, 8)
    }

    private func sectionText(_ text: String) -> some View {
        Text(text)
            .font(.body)
            .foregroundColor(.primary)
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
                .font(.body)
            Spacer()
        }
    }
}

#Preview {
    PrivacyPolicyView()
}
