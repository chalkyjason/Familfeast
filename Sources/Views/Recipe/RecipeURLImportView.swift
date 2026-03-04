import SwiftUI

struct RecipeURLImportView: View {

    // MARK: - Environment

    @Environment(\.aiService) private var aiService
    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    let familyGroup: FamilyGroup?

    // MARK: - State

    @State private var urlString = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var parsedSuggestion: RecipeSuggestion?
    @State private var showingAddRecipe = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "link.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("Import Recipe from URL")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Paste a recipe URL and we'll extract the details using AI")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)

                // URL Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recipe URL")
                        .font(.headline)

                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(.secondary)

                        TextField("https://example.com/recipe", text: $urlString)
                            .textFieldStyle(.plain)
                            #if os(iOS)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            #endif
                            .textContentType(.URL)

                        if !urlString.isEmpty {
                            Button(action: { urlString = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding(.horizontal)

                // Error message
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                // Import button
                Button(action: importRecipe) {
                    if isLoading {
                        HStack {
                            ProgressView()
                                .tint(.white)
                            Text("Importing...")
                        }
                    } else {
                        Label("Import Recipe", systemImage: "arrow.down.circle")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(canImport ? Color.blue.gradient : Color.gray.gradient)
                .cornerRadius(12)
                .padding(.horizontal)
                .disabled(!canImport)

                if aiService == nil {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text("AI service not configured. Set OPENAI_API_KEY to enable URL import.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .navigationTitle("Import Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingAddRecipe) {
                AddRecipeView(familyGroup: familyGroup, suggestion: parsedSuggestion)
            }
        }
    }

    // MARK: - Computed Properties

    private var canImport: Bool {
        !urlString.trimmingCharacters(in: .whitespaces).isEmpty && !isLoading && aiService != nil
    }

    // MARK: - Methods

    private func importRecipe() {
        guard let aiService = aiService else {
            errorMessage = "AI service is not configured"
            return
        }

        let trimmedURL = urlString.trimmingCharacters(in: .whitespaces)
        guard let url = URL(string: trimmedURL) else {
            errorMessage = "Please enter a valid URL"
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                // Fetch URL content
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let htmlString = String(data: data, encoding: .utf8) else {
                    throw URLError(.cannotDecodeContentData)
                }

                // Strip HTML tags and truncate
                let stripped = htmlString
                    .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
                    .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let truncated = String(stripped.prefix(4000))

                // Parse with AI
                let suggestion = try await aiService.parseRecipeFromText(truncated)

                await MainActor.run {
                    isLoading = false
                    parsedSuggestion = suggestion
                    showingAddRecipe = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to import: \(error.localizedDescription)"
                }
            }
        }
    }
}
