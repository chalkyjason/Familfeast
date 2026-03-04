import SwiftUI
import Combine

struct CookingModeView: View {

    // MARK: - Properties

    let recipe: Recipe

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var currentStep = 0
    @State private var steps: [String] = []

    // Timer state
    @State private var timerMinutes = 0
    @State private var timerSecondsRemaining = 0
    @State private var timerIsRunning = false
    @State private var showingTimerAlert = false
    @State private var timerInputMinutes = ""
    @State private var timerPublisher: AnyCancellable?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            ProgressView(value: Double(currentStep + 1), total: Double(max(steps.count, 1)))
                .tint(.blue)
                .padding(.horizontal)
                .padding(.top, 8)

            Text("Step \(currentStep + 1) of \(steps.count)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)

            Spacer()

            // Current step content
            if steps.indices.contains(currentStep) {
                ScrollView {
                    Text(steps[currentStep])
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .padding(32)
                }
            } else {
                Text("No instructions available")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Timer section
            timerSection

            // Navigation buttons
            HStack(spacing: 20) {
                Button(action: previousStep) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Previous")
                    }
                    .font(.headline)
                    .foregroundColor(currentStep > 0 ? .blue : .gray)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(currentStep > 0 ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                .disabled(currentStep <= 0)

                if currentStep < steps.count - 1 {
                    Button(action: nextStep) {
                        HStack {
                            Text("Next")
                            Image(systemName: "chevron.right")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.gradient)
                        .cornerRadius(12)
                    }
                } else {
                    Button(action: { dismiss() }) {
                        HStack {
                            Text("Done")
                            Image(systemName: "checkmark")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.gradient)
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(recipe.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingTimerAlert = true }) {
                    Image(systemName: "timer")
                }
            }
        }
        .alert("Set Timer", isPresented: $showingTimerAlert) {
            TextField("Minutes", text: $timerInputMinutes)
                #if os(iOS)
                .keyboardType(.numberPad)
                #endif
            Button("Start") {
                if let mins = Int(timerInputMinutes), mins > 0 {
                    startTimer(minutes: mins)
                }
                timerInputMinutes = ""
            }
            Button("Cancel", role: .cancel) {
                timerInputMinutes = ""
            }
        } message: {
            Text("Enter the number of minutes for the timer")
        }
        .onAppear {
            steps = parseSteps(from: recipe.instructions)
        }
        .onDisappear {
            stopTimer()
        }
    }

    // MARK: - Timer Section

    private var timerSection: some View {
        Group {
            if timerSecondsRemaining > 0 || timerIsRunning {
                VStack(spacing: 8) {
                    Text(timerDisplayString)
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(timerSecondsRemaining <= 10 ? .red : .primary)

                    HStack(spacing: 16) {
                        Button(action: toggleTimer) {
                            Image(systemName: timerIsRunning ? "pause.fill" : "play.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(timerIsRunning ? Color.orange : Color.green)
                                .clipShape(Circle())
                        }

                        Button(action: resetTimer) {
                            Image(systemName: "stop.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.red)
                                .clipShape(Circle())
                        }
                    }
                }
                .padding()
                .background(.gray.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Computed Properties

    private var timerDisplayString: String {
        let minutes = timerSecondsRemaining / 60
        let seconds = timerSecondsRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Methods

    private func parseSteps(from instructions: String) -> [String] {
        // Try numbered pattern first: "1. Step" or "1: Step"
        let numberedPattern = #"\d+[.:]\s+"#
        if let regex = try? NSRegularExpression(pattern: numberedPattern),
           regex.numberOfMatches(in: instructions, range: NSRange(instructions.startIndex..., in: instructions)) >= 2 {
            let parts = instructions.components(separatedBy: try! NSRegularExpression(pattern: #"\n?\d+[.:]\s+"#))
            let filtered = parts.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            if !filtered.isEmpty { return filtered }
        }

        // Fall back to splitting by newlines
        let lines = instructions.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return lines.isEmpty ? [instructions] : lines
    }

    private func previousStep() {
        if currentStep > 0 {
            withAnimation { currentStep -= 1 }
        }
    }

    private func nextStep() {
        if currentStep < steps.count - 1 {
            withAnimation { currentStep += 1 }
        }
    }

    private func startTimer(minutes: Int) {
        timerMinutes = minutes
        timerSecondsRemaining = minutes * 60
        timerIsRunning = true
        timerPublisher = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if timerSecondsRemaining > 0 {
                    timerSecondsRemaining -= 1
                } else {
                    stopTimer()
                }
            }
    }

    private func toggleTimer() {
        if timerIsRunning {
            timerPublisher?.cancel()
            timerPublisher = nil
            timerIsRunning = false
        } else {
            timerIsRunning = true
            timerPublisher = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    if timerSecondsRemaining > 0 {
                        timerSecondsRemaining -= 1
                    } else {
                        stopTimer()
                    }
                }
        }
    }

    private func resetTimer() {
        stopTimer()
        timerSecondsRemaining = 0
    }

    private func stopTimer() {
        timerPublisher?.cancel()
        timerPublisher = nil
        timerIsRunning = false
    }
}

// MARK: - String Extension for Step Parsing

private extension String {
    func components(separatedBy regex: NSRegularExpression) -> [String] {
        let range = NSRange(startIndex..., in: self)
        let matches = regex.matches(in: self, range: range)

        var parts: [String] = []
        var lastEnd = startIndex

        for match in matches {
            if let matchRange = Range(match.range, in: self) {
                let part = String(self[lastEnd..<matchRange.lowerBound])
                parts.append(part)
                lastEnd = matchRange.upperBound
            }
        }

        let remaining = String(self[lastEnd...])
        parts.append(remaining)

        return parts
    }
}
