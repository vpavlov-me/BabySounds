import SwiftUI

struct ParentGateView: View {
    @Binding var isPresented: Bool
    let onSuccess: () -> Void
    
    @State private var firstNumber = 0
    @State private var secondNumber = 0
    @State private var correctAnswer = 0
    @State private var answerOptions: [Int] = []
    @State private var selectedAnswer: Int? = nil
    @State private var showError = false
    @State private var attempts = 0
    
    private let maxAttempts = 3
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "shield.checkerboard")
                        .font(.system(size: 64))
                        .foregroundColor(.blue)
                    
                    Text("Parent Verification")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("To continue, please solve this simple math problem:")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                
                // Math Problem
                VStack(spacing: 24) {
                    Text("\(firstNumber) + \(secondNumber) = ?")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    // Answer Options
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(answerOptions, id: \.self) { option in
                            Button(action: {
                                selectAnswer(option)
                            }) {
                                Text("\(option)")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(selectedAnswer == option ? .white : .primary)
                                    .frame(height: 64)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedAnswer == option ? Color.blue : Color(.systemGray6))
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Error Message
                if showError {
                    VStack(spacing: 8) {
                        Text("Incorrect answer. Please try again.")
                            .font(.body)
                            .foregroundColor(.red)
                        
                        Text("Attempts: \(attempts)/\(maxAttempts)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.1))
                    )
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 16) {
                    if let selectedAnswer = selectedAnswer {
                        Button(action: checkAnswer) {
                            Text("Submit Answer")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    
                    Button("Cancel") {
                        isPresented = false
                    }
                    .font(.body)
                    .foregroundColor(.secondary)
                }
                .padding(.bottom)
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            generateMathProblem()
        }
        .onChange(of: attempts) { newAttempts in
            if newAttempts >= maxAttempts {
                // Lock out for a few seconds on too many attempts
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    isPresented = false
                }
            }
        }
    }
    
    private func generateMathProblem() {
        firstNumber = Int.random(in: 2...7)
        secondNumber = Int.random(in: 2...7)
        correctAnswer = firstNumber + secondNumber
        
        // Generate wrong answers
        var options = [correctAnswer]
        while options.count < 3 {
            let wrongAnswer = correctAnswer + Int.random(in: -3...3)
            if wrongAnswer > 0 && wrongAnswer != correctAnswer && !options.contains(wrongAnswer) {
                options.append(wrongAnswer)
            }
        }
        
        answerOptions = options.shuffled()
        selectedAnswer = nil
        showError = false
    }
    
    private func selectAnswer(_ answer: Int) {
        selectedAnswer = answer
        showError = false
    }
    
    private func checkAnswer() {
        guard let selectedAnswer = selectedAnswer else { return }
        
        if selectedAnswer == correctAnswer {
            // Correct answer - dismiss and call success callback
            isPresented = false
            onSuccess()
        } else {
            // Wrong answer - show error and generate new problem
            attempts += 1
            showError = true
            
            if attempts < maxAttempts {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    generateMathProblem()
                }
            }
        }
    }
}

// MARK: - Voice Instructions (Future Enhancement)

struct VoiceInstructionsHelper {
    // TODO: Add text-to-speech support for accessibility
    static func speakInstructions() {
        // Could use AVSpeechSynthesizer for voice instructions
        // "Please solve the math problem to continue"
    }
}

#Preview {
    ParentGateView(isPresented: .constant(true)) {
        print("Parent gate passed!")
    }
} 