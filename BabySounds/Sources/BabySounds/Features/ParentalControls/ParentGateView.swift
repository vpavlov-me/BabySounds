import AVFoundation
import SwiftUI

// MARK: - Parent Gate View

/// Enhanced parental gate with multiple challenge types and security features
struct ParentGateView: View {
    @Binding var isPresented: Bool
    let context: ParentGateContext
    let onSuccess: () -> Void
    
    @State private var currentChallenge: ParentGateChallenge?
    @State private var selectedAnswer: String?
    @State private var textAnswer: String = ""
    @State private var showError = false
    @State private var attempts = 0
    @State private var timeRemaining = 30
    @State private var isLocked = false
    @State private var lockoutEndTime: Date?
    
    @Environment(\.dismiss) private var dismiss
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                if isLocked {
                    lockedOutView
                } else {
                    mainContent
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("✕") {
                        handleCancel()
                    }
                    .font(.title2)
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !isLocked {
                        Text("\(timeRemaining)s")
                            .font(.caption)
                            .foregroundColor(timeRemaining <= 10 ? .red : .secondary)
                            .monospacedDigit()
                    }
                }
            }
        }
        .onAppear {
            setupChallenge()
            startTimer()
        }
        .onReceive(timer) { _ in
            updateTimer()
        }
        .interactiveDismissDisabled() // Prevent swipe to dismiss
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 20)
                
                // Security Header
                VStack(spacing: 16) {
                    Image(systemName: context.icon)
                        .font(.system(size: 64))
                        .foregroundColor(context.color)
                        .symbolEffect(.pulse, options: .repeating)
                    
                    Text(context.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(context.description)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                
                // Challenge Content
                if let challenge = currentChallenge {
                    VStack(spacing: 24) {
                        challengeView(for: challenge)
                        
                        // Error Message
                        if showError {
                            errorView
                        }
                        
                        // Submit Button
                        if canSubmit {
                            submitButton
                        }
                    }
                }
                
                Spacer(minLength: 40)
            }
            .padding()
        }
    }
    
    // MARK: - Challenge Views
    
    @ViewBuilder
    private func challengeView(for challenge: ParentGateChallenge) -> some View {
        switch challenge.type {
        case .mathAddition(let a, let b, let options):
            mathChallengeView(
                question: "\(a) + \(b) = ?",
                options: options.map(String.init),
                correctAnswer: String(a + b)
            )
            
        case .mathSubtraction(let a, let b, let options):
            mathChallengeView(
                question: "\(a) - \(b) = ?",
                options: options.map(String.init),
                correctAnswer: String(a - b)
            )
            
        case .readingChallenge(let word, let options):
            readingChallengeView(
                word: word,
                options: options
            )
            
        case .timeChallenge(let hour, let minute, let options):
            timeChallengeView(
                hour: hour,
                minute: minute,
                options: options
            )
            
        case .textInput(let question, let answer):
            textInputChallengeView(
                question: question,
                expectedAnswer: answer
            )
        }
    }
    
    private func mathChallengeView(question: String, options: [String], correctAnswer: String) -> some View {
        VStack(spacing: 24) {
            Text(question)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(options, id: \.self) { option in
                    answerButton(option: option, correctAnswer: correctAnswer)
                }
            }
        }
    }
    
    private func readingChallengeView(word: String, options: [String]) -> some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Read this word:")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text(word)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
            }
            
            Text("Which word did you just read?")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(options, id: \.self) { option in
                    answerButton(option: option, correctAnswer: word)
                }
            }
        }
    }
    
    private func timeChallengeView(hour: Int, minute: Int, options: [String]) -> some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("What time is shown?")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                ClockView(hour: hour, minute: minute)
                    .frame(width: 120, height: 120)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(options, id: \.self) { option in
                    answerButton(option: option, correctAnswer: String(format: "%d:%02d", hour, minute))
                }
            }
        }
    }
    
    private func textInputChallengeView(question: String, expectedAnswer: String) -> some View {
        VStack(spacing: 24) {
            Text(question)
                .font(.title3)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
            
            TextField("Your answer", text: $textAnswer)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.title3)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .onSubmit {
                    if canSubmit {
                        checkAnswer()
                    }
                }
        }
    }
    
    private func answerButton(option: String, correctAnswer: String) -> some View {
        Button(action: {
            selectAnswer(option)
        }) {
            Text(option)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(selectedAnswer == option ? .white : .primary)
                .frame(height: 64)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selectedAnswer == option ? context.color : Color(.systemGray6))
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Error & Submit Views
    
    private var errorView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                Text("Incorrect answer. Please try again.")
                    .font(.body)
                    .foregroundColor(.red)
            }
            
            Text("Attempts: \(attempts)/\(ParentGateManager.maxAttempts)")
                .font(.caption)
                .foregroundColor(.secondary)
                
            if attempts >= ParentGateManager.maxAttempts - 1 {
                Text("One more incorrect attempt will result in a temporary lockout.")
                    .font(.caption2)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.1))
        )
    }
    
    private var submitButton: some View {
        Button(action: checkAnswer) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Submit Answer")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(context.color)
            .cornerRadius(12)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Locked Out View
    
    private var lockedOutView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "lock.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.red)
            
            Text("Too Many Attempts")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Please wait before trying again.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let lockoutEnd = lockoutEndTime {
                Text("Try again in \(Int(lockoutEnd.timeIntervalSinceNow))s")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
                    .monospacedDigit()
            }
            
            Spacer()
            
            Button("Close") {
                handleCancel()
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.gray)
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .padding()
    }
    
    // MARK: - Computed Properties
    
    private var canSubmit: Bool {
        guard let challenge = currentChallenge else { return false }
        
        switch challenge.type {
        case .textInput:
            return !textAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        default:
            return selectedAnswer != nil
        }
    }
    
    // MARK: - Actions
    
    private func setupChallenge() {
        currentChallenge = ParentGateManager.generateChallenge(for: context)
        selectedAnswer = nil
        textAnswer = ""
        showError = false
    }
    
    private func selectAnswer(_ answer: String) {
        selectedAnswer = answer
        showError = false
        
        // Auto-submit after selection for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if selectedAnswer == answer { // Only if still selected
                checkAnswer()
            }
        }
    }
    
    private func checkAnswer() {
        guard let challenge = currentChallenge else { return }
        
        let userAnswer: String
        switch challenge.type {
        case .textInput:
            userAnswer = textAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        default:
            userAnswer = selectedAnswer ?? ""
        }
        
        if challenge.isCorrectAnswer(userAnswer) {
            // Success!
            ParentGateManager.recordSuccess(for: context)
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            dismiss()
            onSuccess()
        } else {
            // Wrong answer
            attempts += 1
            showError = true
            
            ParentGateManager.recordFailedAttempt(for: context)
            
            // Error haptic
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.error)
            
            if attempts >= ParentGateManager.maxAttempts {
                triggerLockout()
            } else {
                // Generate new challenge after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    if !isLocked {
                        setupChallenge()
                    }
                }
            }
        }
    }
    
    private func triggerLockout() {
        isLocked = true
        lockoutEndTime = Date().addingTimeInterval(ParentGateManager.lockoutDuration)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + ParentGateManager.lockoutDuration) {
            dismiss()
        }
    }
    
    private func handleCancel() {
        ParentGateManager.recordCancellation(for: context)
        dismiss()
    }
    
    private func startTimer() {
        timeRemaining = 30
    }
    
    private func updateTimer() {
        if isLocked {
            // Update lockout countdown
            if let lockoutEnd = lockoutEndTime, lockoutEnd <= Date() {
                dismiss()
            }
        } else {
            timeRemaining -= 1
            if timeRemaining <= 0 {
                // Time expired
                ParentGateManager.recordTimeout(for: context)
                dismiss()
            }
        }
    }
}

// MARK: - Clock View

struct ClockView: View {
    let hour: Int
    let minute: Int
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary, lineWidth: 2)
            
            // Hour markers
            ForEach(0..<12) { i in
                Rectangle()
                    .fill(Color.primary)
                    .frame(width: 2, height: 8)
                    .offset(y: -40)
                    .rotationEffect(.degrees(Double(i) * 30))
            }
            
            // Hour hand
            Rectangle()
                .fill(Color.primary)
                .frame(width: 3, height: 25)
                .offset(y: -12.5)
                .rotationEffect(.degrees(Double(hour % 12) * 30 + Double(minute) * 0.5))
            
            // Minute hand
            Rectangle()
                .fill(Color.primary)
                .frame(width: 2, height: 35)
                .offset(y: -17.5)
                .rotationEffect(.degrees(Double(minute) * 6))
            
            // Center dot
            Circle()
                .fill(Color.primary)
                .frame(width: 6, height: 6)
        }
    }
}

// MARK: - Preview

#Preview {
    Group {
        ParentGateView(
            isPresented: .constant(true),
            context: .settings
        )            {
                print("Parent gate passed!")
            }
        
        ParentGateView(
            isPresented: .constant(true),
            context: .paywall
        )            {
                print("Paywall access granted!")
            }
    }
}
