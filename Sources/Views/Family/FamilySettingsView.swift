import SwiftUI
import SwiftData
import CloudKit

struct FamilySettingsView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.cloudKitService) private var cloudKitService

    // MARK: - Properties

    let familyGroup: FamilyGroup?

    // MARK: - State

    @State private var showingInviteSheet = false
    @State private var showingShareSheet = false
    @State private var isCloudKitAvailable = false
    @State private var errorMessage: String?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // Family info section
                if let group = familyGroup {
                    familyInfoSection(group)
                    membersSection(group)
                    inviteSection
                }

                // Settings
                preferencesSection
                dataSection
                aboutSection
            }
            .navigationTitle("Family Settings")
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
            .sheet(isPresented: $showingInviteSheet) {
                InviteFamilyMemberView(familyGroup: familyGroup)
            }
            .onAppear {
                checkCloudKitStatus()
            }
        }
    }

    // MARK: - Sections

    private func familyInfoSection(_ group: FamilyGroup) -> some View {
        Section {
            HStack {
                Image(systemName: "house.fill")
                    .font(.title)
                    .foregroundColor(.blue)
                    .frame(width: 50, height: 50)
                    .background(.blue.opacity(0.1))
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.headline)

                    Text("Created \(group.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: {}) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                }
            }
        } header: {
            Text("Family Group")
        }
    }

    private func membersSection(_ group: FamilyGroup) -> some View {
        Section {
            if let members = group.members {
                ForEach(members) { member in
                    MemberRow(member: member)
                }
            } else {
                Text("No members yet")
                    .foregroundColor(.secondary)
            }
        } header: {
            HStack {
                Text("Members")
                Spacer()
                Text("\(group.members?.count ?? 0)")
                    .foregroundColor(.secondary)
            }
        }
    }

    private var inviteSection: some View {
        Section {
            Button(action: { showingInviteSheet = true }) {
                Label("Invite Family Member", systemImage: "person.badge.plus")
            }

            if isCloudKitAvailable {
                Button(action: { showingShareSheet = true }) {
                    Label("Share via iCloud", systemImage: "square.and.arrow.up")
                }
            } else {
                HStack {
                    Label("iCloud Sharing", systemImage: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Spacer()
                    Text("Sign in to iCloud")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var preferencesSection: some View {
        Section("Preferences") {
            NavigationLink(destination: Text("Dietary Restrictions")) {
                Label("Dietary Restrictions", systemImage: "leaf")
            }

            NavigationLink(destination: Text("Cuisine Preferences")) {
                Label("Cuisine Preferences", systemImage: "globe")
            }

            NavigationLink(destination: Text("Budget Settings")) {
                Label("Budget Settings", systemImage: "dollarsign.circle")
            }

            NavigationLink(destination: Text("Notifications")) {
                Label("Notifications", systemImage: "bell")
            }
        }
    }

    private var dataSection: some View {
        Section("Data") {
            Button(action: {}) {
                Label("Export Data", systemImage: "square.and.arrow.up")
            }

            Button(action: {}) {
                Label("Sync Status", systemImage: "arrow.triangle.2.circlepath")
            }

            Button(role: .destructive, action: {}) {
                Label("Clear Local Cache", systemImage: "trash")
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }

            Link(destination: URL(string: "https://familyfeast.app/privacy")!) {
                Label("Privacy Policy", systemImage: "hand.raised")
            }

            Link(destination: URL(string: "https://familyfeast.app/terms")!) {
                Label("Terms of Service", systemImage: "doc.text")
            }

            Button(action: {}) {
                Label("Send Feedback", systemImage: "envelope")
            }
        }
    }

    // MARK: - Methods

    private func checkCloudKitStatus() {
        Task {
            do {
                let status = try await cloudKitService.checkAccountStatus()
                await MainActor.run {
                    isCloudKitAvailable = (status == .available)
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to check iCloud status: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct MemberRow: View {
    let member: FamilyMember

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(roleColor.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay {
                    Text(member.displayName.prefix(1).uppercased())
                        .font(.headline)
                        .foregroundColor(roleColor)
                }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(member.displayName)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text(member.role.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if !member.hasAcceptedInvite {
                        Text("• Pending")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }

            Spacer()

            if member.role == .owner {
                Image(systemName: "crown.fill")
                    .foregroundColor(.yellow)
            }
        }
        .padding(.vertical, 4)
    }

    private var roleColor: Color {
        switch member.role {
        case .owner: return .purple
        case .headOfHousehold: return .blue
        case .member: return .green
        case .child: return .orange
        }
    }
}

struct InviteFamilyMemberView: View {
    let familyGroup: FamilyGroup?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.cloudKitService) private var cloudKitService

    @State private var email = ""
    @State private var displayName = ""
    @State private var selectedRole: FamilyRole = .member
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Member Details") {
                    TextField("Email or Phone", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    TextField("Display Name", text: $displayName)

                    Picker("Role", selection: $selectedRole) {
                        ForEach([FamilyRole.member, .headOfHousehold, .child], id: \.self) { role in
                            Text(role.rawValue.capitalized).tag(role)
                        }
                    }
                }

                Section {
                    Button(action: sendInvite) {
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Send Invitation")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(email.isEmpty || displayName.isEmpty || isLoading)
                }
            }
            .navigationTitle("Invite Member")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
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

    private func sendInvite() {
        isLoading = true

        Task {
            do {
                // In a real implementation, this would:
                // 1. Create a CKShare
                // 2. Add the participant
                // 3. Send the invitation via CloudKit

                // For now, just show success
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }

            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to send invitation: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(
        for: FamilyGroup.self, FamilyMember.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let group = FamilyGroup(name: "Test Family", ownerUserID: "test")
    let member1 = FamilyMember(
        userRecordID: "user1",
        displayName: "John Doe",
        role: .owner,
        hasAcceptedInvite: true
    )
    let member2 = FamilyMember(
        userRecordID: "user2",
        displayName: "Jane Doe",
        role: .member,
        hasAcceptedInvite: false
    )

    member1.familyGroup = group
    member2.familyGroup = group

    container.mainContext.insert(group)
    container.mainContext.insert(member1)
    container.mainContext.insert(member2)

    return FamilySettingsView(familyGroup: group)
        .modelContainer(container)
}
