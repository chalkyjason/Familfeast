import SwiftUI
import SwiftData
import Charts

struct BudgetDashboardView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - Properties

    let familyGroup: FamilyGroup

    // MARK: - Queries

    @Query(sort: \MealSession.startDate, order: .reverse)
    private var mealSessions: [MealSession]

    @Query(sort: \ShoppingList.createdAt, order: .reverse)
    private var shoppingLists: [ShoppingList]

    // MARK: - State

    @State private var selectedTimeRange: TimeRange = .month
    @State private var showingBudgetSettings = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Time range selector
                    timeRangePicker

                    // Current month summary
                    currentMonthSummary

                    // Spending chart
                    spendingChartSection

                    // Sessions breakdown
                    sessionsBreakdownSection

                    // Savings insights
                    savingsInsightsSection

                    // Recent transactions
                    recentTransactionsSection
                }
                .padding()
            }
            .navigationTitle("Budget Tracker")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingBudgetSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingBudgetSettings) {
                BudgetSettingsView(familyGroup: familyGroup)
            }
        }
    }

    // MARK: - Subviews

    private var timeRangePicker: some View {
        Picker("Time Range", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.displayName).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }

    private var currentMonthSummary: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("This Month")
                    .font(.headline)
                Spacer()
                Text(monthString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Budget card
            VStack(spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Budget")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("$\(String(format: "%.2f", Double(totalBudget) / 100.0))")
                            .font(.title)
                            .fontWeight(.bold)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Spent")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("$\(String(format: "%.2f", Double(totalSpent) / 100.0))")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(totalSpent > totalBudget ? .red : .green)
                    }
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.gray.opacity(0.2))

                        RoundedRectangle(cornerRadius: 8)
                            .fill(progressGradient)
                            .frame(width: min(geometry.size.width, geometry.size.width * progressPercentage))
                    }
                }
                .frame(height: 16)

                // Remaining
                HStack {
                    Image(systemName: budgetStatusIcon)
                        .foregroundColor(budgetStatusColor)

                    Text(budgetStatusText)
                        .font(.subheadline)
                        .foregroundColor(budgetStatusColor)

                    Spacer()

                    Text("$\(String(format: "%.2f", Double(abs(remaining)) / 100.0))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(budgetStatusColor)
                }
            }
            .padding()
            .background(.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }

    private var spendingChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending Trend")
                .font(.headline)

            Chart {
                ForEach(chartData, id: \.date) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Amount", Double(dataPoint.amount) / 100.0)
                    )
                    .foregroundStyle(.blue.gradient)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Amount", Double(dataPoint.amount) / 100.0)
                    )
                    .foregroundStyle(.blue.opacity(0.1).gradient)
                    .interpolationMethod(.catmullRom)
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text("$\(Int(amount))")
                        }
                    }
                }
            }
            .padding()
            .background(.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }

    private var sessionsBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Sessions")
                .font(.headline)

            ForEach(recentSessions) { session in
                SessionBudgetCard(session: session)
            }
        }
    }

    private var savingsInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Savings Insights")
                .font(.headline)

            VStack(spacing: 12) {
                InsightCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Average Weekly Cost",
                    value: "$\(String(format: "%.2f", averageWeeklyCost))",
                    color: .blue
                )

                InsightCard(
                    icon: "dollarsign.circle",
                    title: "Cost Per Meal",
                    value: "$\(String(format: "%.2f", costPerMeal))",
                    color: .green
                )

                if savingsVsPrevious != 0 {
                    InsightCard(
                        icon: savingsVsPrevious > 0 ? "arrow.down.circle" : "arrow.up.circle",
                        title: "vs. Last Month",
                        value: "\(savingsVsPrevious > 0 ? "Saved" : "Spent") $\(String(format: "%.2f", abs(Double(savingsVsPrevious) / 100.0)))",
                        color: savingsVsPrevious > 0 ? .green : .red
                    )
                }
            }
        }
    }

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Shopping Trips")
                .font(.headline)

            ForEach(recentLists) { list in
                TransactionRow(shoppingList: list)
            }
        }
    }

    // MARK: - Computed Properties

    private var filteredSessions: [MealSession] {
        let cutoffDate: Date
        switch selectedTimeRange {
        case .week:
            cutoffDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
        case .month:
            cutoffDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        case .year:
            cutoffDate = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        }

        return mealSessions.filter { session in
            session.startDate >= cutoffDate && session.familyGroup?.id == familyGroup.id
        }
    }

    private var recentSessions: [MealSession] {
        Array(filteredSessions.prefix(5))
    }

    private var recentLists: [ShoppingList] {
        shoppingLists
            .filter { $0.familyGroup?.id == familyGroup.id && $0.isComplete }
            .prefix(5)
            .map { $0 }
    }

    private var totalBudget: Int {
        filteredSessions.compactMap { $0.budgetLimit }.reduce(0, +)
    }

    private var totalSpent: Int {
        filteredSessions.compactMap { $0.actualSpending }.reduce(0, +)
    }

    private var remaining: Int {
        totalBudget - totalSpent
    }

    private var progressPercentage: CGFloat {
        guard totalBudget > 0 else { return 0 }
        return min(CGFloat(totalSpent) / CGFloat(totalBudget), 1.0)
    }

    private var progressGradient: LinearGradient {
        if totalSpent > totalBudget {
            return LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
        } else if Double(totalSpent) > Double(totalBudget) * 0.9 {
            return LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
        } else {
            return LinearGradient(colors: [.green, .blue], startPoint: .leading, endPoint: .trailing)
        }
    }

    private var budgetStatusIcon: String {
        if totalSpent > totalBudget {
            return "exclamationmark.triangle.fill"
        } else if Double(totalSpent) > Double(totalBudget) * 0.9 {
            return "exclamationmark.circle.fill"
        } else {
            return "checkmark.circle.fill"
        }
    }

    private var budgetStatusColor: Color {
        if totalSpent > totalBudget {
            return .red
        } else if Double(totalSpent) > Double(totalBudget) * 0.9 {
            return .orange
        } else {
            return .green
        }
    }

    private var budgetStatusText: String {
        if remaining >= 0 {
            return "Remaining"
        } else {
            return "Over Budget"
        }
    }

    private var monthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }

    private var averageWeeklyCost: Double {
        guard !filteredSessions.isEmpty else { return 0 }
        let totalCost = filteredSessions.compactMap { $0.actualSpending }.reduce(0, +)
        return Double(totalCost) / Double(filteredSessions.count) / 100.0
    }

    private var costPerMeal: Double {
        let totalMeals = filteredSessions.reduce(0) { $0 + ($1.scheduledMeals?.count ?? 0) }
        guard totalMeals > 0 else { return 0 }
        return Double(totalSpent) / Double(totalMeals) / 100.0
    }

    private var savingsVsPrevious: Int {
        // Calculate difference vs previous month
        // Simplified calculation
        let previousTotal = 0 // Would calculate from previous period
        return previousTotal - totalSpent
    }

    private var chartData: [ChartDataPoint] {
        var data: [ChartDataPoint] = []

        for session in filteredSessions {
            if let actualSpending = session.actualSpending {
                data.append(ChartDataPoint(date: session.startDate, amount: actualSpending))
            }
        }

        return data.sorted { $0.date < $1.date }
    }
}

// MARK: - Supporting Views

struct SessionBudgetCard: View {
    let session: MealSession

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(session.startDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let budget = session.budgetLimit {
                    Text("$\(String(format: "%.2f", Double(budget) / 100.0))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let actual = session.actualSpending, let budget = session.budgetLimit {
                    Text("$\(String(format: "%.2f", Double(actual) / 100.0))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(actual > budget ? .red : .green)
                }
            }

            // Status indicator
            Image(systemName: session.budgetStatus().icon)
                .foregroundColor(statusColor(session.budgetStatus()))
        }
        .padding()
        .background(.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func statusColor(_ status: BudgetStatus) -> Color {
        switch status {
        case .noBudget: return .gray
        case .underBudget: return .green
        case .nearLimit: return .orange
        case .overBudget: return .red
        }
    }
}

struct InsightCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            Spacer()
        }
        .padding()
        .background(.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct TransactionRow: View {
    let shoppingList: ShoppingList

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(shoppingList.name)
                    .font(.subheadline)

                Text(shoppingList.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let actual = shoppingList.actualTotal {
                Text("$\(String(format: "%.2f", Double(actual) / 100.0))")
                    .font(.subheadline)
                    .fontWeight(.medium)
            } else if let estimated = shoppingList.estimatedTotal {
                Text("~$\(String(format: "%.2f", Double(estimated) / 100.0))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct BudgetSettingsView: View {
    let familyGroup: FamilyGroup

    @Environment(\.dismiss) private var dismiss
    @State private var monthlyBudget = ""
    @State private var notifications = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Budget Settings") {
                    TextField("Monthly Budget", text: $monthlyBudget)
                        .keyboardType(.decimalPad)

                    Toggle("Budget Alerts", isOn: $notifications)
                }

                Section("Preferences") {
                    Toggle("Show Cost Estimates", isOn: .constant(true))
                    Toggle("Track Actual Spending", isOn: .constant(true))
                }
            }
            .navigationTitle("Budget Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Supporting Types

enum TimeRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"

    var displayName: String {
        rawValue
    }
}

struct ChartDataPoint {
    let date: Date
    let amount: Int
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(
        for: FamilyGroup.self, MealSession.self, ShoppingList.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let group = FamilyGroup(name: "Test Family", ownerUserID: "test")
    container.mainContext.insert(group)

    return BudgetDashboardView(familyGroup: group)
        .modelContainer(container)
}
