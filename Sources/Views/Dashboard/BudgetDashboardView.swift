import SwiftUI
import SwiftData

struct BudgetDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \MealSession.startDate, order: .reverse)
    private var mealSessions: [MealSession]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Overall Budget Summary
                    budgetSummaryCard
                    
                    // Spending Trend Chart (Simplified)
                    spendingTrendCard
                    
                    // Session Breakdown
                    Text("Recent Sessions")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ForEach(mealSessions.prefix(5)) { session in
                        SessionBudgetRow(session: session)
                    }
                }
                .padding()
            }
            .navigationTitle("Budget Tracking")
        }
    }
    
    private var budgetSummaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Spent (This Month)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(totalSpentThisMonth.asDollarString)
                        .font(.title)
                        .fontWeight(.bold)
                }
                Spacer()
                Image(systemName: "chart.pie.fill")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Avg. per Meal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(averageCostPerMeal.asDollarString)
                        .font(.headline)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Sessions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(mealSessions.count)")
                        .font(.headline)
                }
            }
        }
        .cardStyle()
    }
    
    private var spendingTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending Trend")
                .font(.headline)
            
            // Simplified "chart" using rectangles
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(mealSessions.prefix(7).reversed()) { session in
                    VStack {
                        let cost = Double(session.calculateEstimatedCost())
                        let maxCost = Double(mealSessions.map { $0.calculateEstimatedCost() }.max() ?? 1)
                        let height = (cost / maxCost) * 100
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(session.budgetStatus() == .underBudget ? Color.green : Color.orange)
                            .frame(width: 30, height: max(height, 5))
                        
                        Text(session.startDate.formatted(.dateTime.day().month()))
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
        }
        .cardStyle()
    }
    
    // MARK: - Computed Properties
    
    private var totalSpentThisMonth: Int {
        let calendar = Calendar.current
        let now = Date()
        return mealSessions
            .filter { calendar.isDate($0.startDate, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.calculateEstimatedCost() }
    }
    
    private var averageCostPerMeal: Int {
        let totalCost = mealSessions.reduce(0) { $0 + $1.calculateEstimatedCost() }
        let totalMeals = mealSessions.reduce(0) { $0 + ($1.scheduledMeals?.count ?? 0) }
        return totalMeals > 0 ? totalCost / totalMeals : 0
    }
}

struct SessionBudgetRow: View {
    let session: MealSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(session.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(session.startDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(session.calculateEstimatedCost().asDollarString)
                    .font(.subheadline)
                    .fontWeight(.bold)
                
                let status = session.budgetStatus()
                Text(status.displayText)
                    .font(.system(size: 10))
                    .foregroundColor(statusColor(status))
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func statusColor(_ status: BudgetStatus) -> Color {
        switch status {
        case .underBudget: return .green
        case .nearLimit: return .orange
        case .overBudget: return .red
        case .noBudget: return .gray
        }
    }
}

#Preview {
    BudgetDashboardView()
        .modelContainer(for: [MealSession.self, ScheduledMeal.self], inMemory: true)
}
