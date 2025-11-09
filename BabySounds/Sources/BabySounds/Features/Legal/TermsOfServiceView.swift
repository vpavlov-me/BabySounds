import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    termsContent
                }
                .padding()
            }
            .navigationTitle("Terms of Service")
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

    private var termsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Last Updated: November 2, 2025")
                .font(.caption)
                .foregroundColor(.secondary)

            Group {
                sectionTitle("1. Acceptance of Terms")
                sectionText(
                    "By downloading or using Baby Sounds, you agree to these Terms of Service. If you do not agree, do not use the app."
                )

                sectionTitle("2. Age Requirements")
                bulletPoint("App is designed for babies and children under parental supervision")
                bulletPoint("Users under 13 must have parental consent")
                bulletPoint("Parents/guardians are responsible for all app usage")
                bulletPoint("All purchases require parental authorization")

                sectionTitle("3. License Grant")
                sectionText("Baby Sounds grants you a limited, non-exclusive, non-transferable license to:")
                bulletPoint("Use the app on Apple devices you own or control")
                bulletPoint("Access premium features with active subscription")
                bulletPoint("Download content for offline use (Premium feature)")

                sectionTitle("4. Subscription Terms")
                sectionText("**Monthly Subscription**: Auto-renews monthly")
                sectionText("**Annual Subscription**: Auto-renews yearly")
                bulletPoint("7-day free trial for first-time subscribers")
                bulletPoint("Cancel anytime via App Store Settings")
                bulletPoint("Refunds subject to Apple's refund policy")
                bulletPoint("Price changes notified 30 days in advance")
            }

            Group {
                sectionTitle("5. Parental Responsibility")
                sectionText("Parents and guardians are responsible for:")
                bulletPoint("Monitoring app usage and volume levels")
                bulletPoint("Ensuring hearing safety compliance")
                bulletPoint("All purchase decisions and subscription management")
                bulletPoint("Device access and parental controls")

                sectionTitle("6. Hearing Safety Disclaimer")
                sectionText("**IMPORTANT SAFETY INFORMATION**")
                bulletPoint("Always monitor volume levels when baby is using app")
                bulletPoint("Follow WHO hearing safety guidelines")
                bulletPoint("Take breaks from audio usage as recommended")
                bulletPoint("Use headphones/speakers appropriate for children")
                sectionText(
                    "Baby Sounds implements safety features but cannot guarantee hearing protection. Parents must supervise usage."
                )

                sectionTitle("7. Prohibited Uses")
                sectionText("You may not:")
                bulletPoint("Reverse engineer, decompile, or disassemble the app")
                bulletPoint("Remove copyright or proprietary notices")
                bulletPoint("Use app for commercial purposes without permission")
                bulletPoint("Circumvent parental gate or safety features")
                bulletPoint("Share subscription access")
            }

            Group {
                sectionTitle("8. Content Ownership")
                bulletPoint("All sounds, music, and content remain property of Baby Sounds")
                bulletPoint("Premium content available only with active subscription")
                bulletPoint("Offline downloads deleted upon subscription cancellation")
                bulletPoint("No redistribution or commercial use of content")

                sectionTitle("9. Subscription Cancellation")
                bulletPoint("Cancel anytime via iPhone Settings → Subscriptions")
                bulletPoint("Access continues until end of billing period")
                bulletPoint("No refunds for partial subscription periods")
                bulletPoint("Premium features disabled after subscription ends")
                bulletPoint("Free features remain available")

                sectionTitle("10. Disclaimers")
                sectionText("**APP PROVIDED \"AS IS\"**")
                bulletPoint("No guarantee of uninterrupted operation")
                bulletPoint("Not a medical device or sleep aid")
                bulletPoint("Results may vary between children")
                bulletPoint("Not responsible for hearing damage from misuse")

                sectionTitle("11. Limitation of Liability")
                sectionText("Baby Sounds shall not be liable for:")
                bulletPoint("Hearing damage from excessive volume")
                bulletPoint("Device damage or data loss")
                bulletPoint("Indirect or consequential damages")
                bulletPoint("Third-party service disruptions")
                sectionText("Maximum liability limited to subscription price paid.")
            }

            Group {
                sectionTitle("12. Privacy")
                sectionText("See our Privacy Policy for detailed information on:")
                bulletPoint("Data collection and usage")
                bulletPoint("COPPA, GDPR, CCPA compliance")
                bulletPoint("Children's privacy protection")
                bulletPoint("Your rights and controls")

                sectionTitle("13. Apple Terms")
                sectionText("Subscriptions purchased through:")
                bulletPoint("Apple App Store")
                bulletPoint("Subject to Apple's Terms of Service")
                bulletPoint("Managed via Apple ID and Family Sharing")
                bulletPoint("Refunds handled by Apple Support")

                sectionTitle("14. Changes to Terms")
                bulletPoint("We may update these terms with 30 days notice")
                bulletPoint("Material changes require acceptance")
                bulletPoint("Continued use indicates acceptance")

                sectionTitle("15. Termination")
                sectionText("We may terminate access for:")
                bulletPoint("Terms of Service violations")
                bulletPoint("Fraudulent purchase attempts")
                bulletPoint("Abusive behavior")
                bulletPoint("Legal compliance")

                sectionTitle("16. Contact Information")
                sectionText("Questions about these Terms:")
                bulletPoint("Email: support@babysounds.app")
                bulletPoint("GitHub: github.com/vpavlov-me/BabySounds")

                sectionTitle("17. Governing Law")
                sectionText(
                    "These Terms governed by laws of United States. Disputes resolved through binding arbitration."
                )
            }

            Divider()
                .padding(.vertical)

            Text(
                "By using Baby Sounds, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service."
            )
            .font(.callout)
            .italic()

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
    TermsOfServiceView()
}
