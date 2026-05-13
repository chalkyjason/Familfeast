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
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Theme.primary.opacity(0.1))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "square.and.arrow.down.on.square.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Theme.primary)
                        }

                        Text("Import Recipe")
                            .font(.system(size: 28, weight: .bold, design: .rounded))

                        Text("Paste a link from a website, YouTube, or TikTok and we'll handle the rest")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top)

                    // URL Input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recipe Link")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))

                        HStack {
                            Image(systemName: isVideoLink ? "video.fill" : "globe")
                                .foregroundColor(Theme.primary)

                            TextField("https://...", text: $urlString)
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
                        .padding(16)
                        .background(Theme.cardBackground)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
                    }
                    .padding(.horizontal)

                    // Hints
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Supported Sources")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 16) {
                            SourceBadge(icon: "safari", name: "Websites")
                            SourceBadge(icon: "play.tv.fill", name: "YouTube")
                            SourceBadge(icon: "music.note", name: "TikTok")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                    }

                    // Import button
                    Button(action: importRecipe) {
                        if isLoading {
                            HStack {
                                ProgressView()
                                    .tint(.white)
                                Text("Analyzing Source...")
                            }
                        } else {
                            Text("Extract Recipe")
                                .fontWeight(.bold)
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(canImport ? Theme.primary.gradient : Color.gray.gradient)
                    .cornerRadius(14)
                    .padding(.horizontal)
                    .disabled(!canImport)

                    Spacer()
                }
            }
            .background(Theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showingAddRecipe) {
                AddRecipeView(familyGroup: familyGroup, suggestion: parsedSuggestion)
            }
        }
    }

    // MARK: - Computed Properties

    private var isVideoLink: Bool {
        let low = urlString.lowercased()
        return low.contains("youtube.com") || low.contains("youtu.be") || low.contains("tiktok.com")
    }

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
                let suggestion: RecipeSuggestion
                
                if isVideoLink {
                    suggestion = try await aiService.parseRecipeFromVideoURL(url)
                } else {
                    suggestion = try await aiService.parseRecipeFromURL(url)
                }

                await MainActor.run {
                    isLoading = false
                    parsedSuggestion = suggestion
                    showingAddRecipe = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to extract recipe. \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct SourceBadge: View {
    let icon: String
    let name: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(name)
        }
        .font(.caption)
        .fontWeight(.medium)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}
