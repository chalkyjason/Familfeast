import SwiftUI
import SwiftData

struct OnboardingView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.cloudKitService) private var cloudKitService

    // MARK: - Bindings

    @Binding var isPresented: Bool
    let onComplete: (FamilyGroup) -> Void

    // MARK: - Types

    private enum OnboardingStep: Int, CaseIterable {
        case welcome = 0
        case setupFamily = 1
        case completion = 2
    }

    // MARK: - State

    @State private var currentStep: OnboardingStep = .welcome
    @State private var familyName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Progress indicator
                ProgressView(value: Double(currentStep.rawValue), total: 2)
                    .padding(.horizontal)

                Group {
                    switch currentStep {
                    case .welcome:
                        welcomeStep
                    case .setupFamily:
                        setupFamilyStep
                    case .completion:
                        completionStep
                    }
                }
            }
            .navigationTitle("Welcome to FamilyFeast")
            .navigationBarTitleDisplayMode(.inline)
            .overlay {
                if isLoading {
                    ProgressView("Setting up...")
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(12)
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue.gradient)
                    .padding(.top, 20)

                Text("FamilyFeast")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Collaborative meal planning made easy")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 14) {
                    FeatureRow(
                        icon: "person.3.fill",
                        title: "Family Voting",
                        description: "Everyone gets a say in what's for dinner"
                    )

                    FeatureRow(
                        icon: "cart.fill",
                        title: "Smart Shopping Lists",
                        description: "Automatically generated with budget tracking"
                    )

                    FeatureRow(
                        icon: "sparkles",
                        title: "AI Suggestions",
                        description: "Get personalized recipe recommendations"
                    )

                    FeatureRow(
                        icon: "calendar",
                        title: "Meal Scheduling",
                        description: "Plan your week with drag-and-drop calendar"
                    )
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(16)
                .padding(.horizontal)

                Button(action: {
                    withAnimation {
                        currentStep = .setupFamily
                    }
                }) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue.gradient)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
    }

    private var setupFamilyStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "house.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green.gradient)
                    .padding(.top, 40)

                Text("Create Your Family Group")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Give your family group a name. You can invite members later.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                TextField("Family Name", text: $familyName)
                    .padding(12)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .autocorrectionDisabled()

                HStack(spacing: 16) {
                    Button("Back") {
                        withAnimation {
                            currentStep = .welcome
                        }
                    }
                    .buttonStyle(.bordered)

                    Button(action: createFamilyGroup) {
                        Text("Create Family")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(familyName.isEmpty ? Color.gray : Color.green)
                            .cornerRadius(12)
                    }
                    .disabled(familyName.isEmpty)
                }
                .padding(.horizontal)
                .padding(.top, 20)
            }
        }
    }

    private var completionStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(.green.gradient)

            Text("You're All Set!")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Your family group is ready. Start adding recipes and planning meals!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            Button(action: {
                isPresented = false
            }) {
                Text("Start Planning")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.green.gradient)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Private Methods

    private func createFamilyGroup() {
        isLoading = true

        // Try to get iCloud user ID, fall back to local UUID
        Task {
            var userIDString: String = UUID().uuidString

            do {
                let userRecordID = try await cloudKitService.fetchUserRecordID()
                userIDString = userRecordID.recordName
            } catch {
                print("CloudKit not available, using local ID: \(error.localizedDescription)")
            }

            // Create family group
            let group = FamilyGroup(
                name: familyName,
                ownerUserID: userIDString
            )

            // Create owner member
            let owner = FamilyMember(
                userRecordID: userIDString,
                displayName: "Me",
                role: .owner,
                hasAcceptedInvite: true
            )
            owner.familyGroup = group

            // Save to SwiftData
            modelContext.insert(group)
            modelContext.insert(owner)

            do {
                try modelContext.save()
            } catch {
                print("Failed to save: \(error)")
            }

            await MainActor.run {
                isLoading = false
                withAnimation {
                    currentStep = .completion
                }
                onComplete(group)
            }
        }
    }
}

// MARK: - Supporting Views

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(
        isPresented: .constant(true),
        onComplete: { _ in }
    )
    .modelContainer(for: FamilyGroup.self, inMemory: true)
}
