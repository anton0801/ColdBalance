import SwiftUI

struct BalanceInsightsView: View {
    @EnvironmentObject var viewModel: BalanceViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Best Saving Day
                        if let bestDay = viewModel.getBestSavingDay() {
                            InsightCard(
                                icon: "star.fill",
                                title: "Best Saving Day",
                                value: bestDay.day,
                                subtitle: "Saved $\(Int(bestDay.amount))",
                                color: Theme.income
                            )
                        }
                        
                        // Biggest Expense
                        if let biggestExpense = viewModel.getBiggestExpense() {
                            InsightCard(
                                icon: "exclamationmark.triangle.fill",
                                title: "Biggest Expense",
                                value: biggestExpense.category,
                                subtitle: "$\(Int(biggestExpense.amount))",
                                color: Theme.expense
                            )
                        }
                        
                        // Average Daily Spend
                        let avgSpend = viewModel.getAverageDailySpend()
                        if avgSpend > 0 {
                            InsightCard(
                                icon: "chart.bar.fill",
                                title: "Average Daily Spend",
                                value: "$\(Int(avgSpend))",
                                subtitle: "Per day this month",
                                color: Theme.neutral
                            )
                        }
                        
                        // Savings Rate
                        if viewModel.monthIncome > 0 {
                            let savingsRate = ((viewModel.monthIncome - viewModel.monthExpense) / viewModel.monthIncome) * 100
                            InsightCard(
                                icon: "percent",
                                title: "Savings Rate",
                                value: "\(Int(savingsRate))%",
                                subtitle: "Of income saved",
                                color: Theme.progress
                            )
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Theme.secondaryText)
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Insights")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Theme.primaryText)
                }
            }
        }
    }
}

struct InsightCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.secondaryText)
                
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.primaryText)
                
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.secondaryText)
            }
            
            Spacer()
        }
        .padding(20)
        .background(Theme.cardBackground)
        .cornerRadius(20)
    }
}
