import SwiftUI

struct MonthlyOverviewView: View {
    @EnvironmentObject var viewModel: BalanceViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Month Header
                        monthHeader
                        
                        // Income Bar
                        progressBar(
                            title: "Income",
                            amount: viewModel.monthIncome,
                            total: max(viewModel.monthIncome, viewModel.monthExpense),
                            color: Theme.income
                        )
                        
                        // Expense Bar
                        progressBar(
                            title: "Expenses",
                            amount: viewModel.monthExpense,
                            total: max(viewModel.monthIncome, viewModel.monthExpense),
                            color: Theme.expense
                        )
                        
                        // Net Result
                        netResultCard
                        
                        // Category Breakdown
                        categoryBreakdown
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
                    Text("Monthly Overview")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Theme.primaryText)
                }
            }
        }
    }
    
    private var monthHeader: some View {
        VStack(spacing: 8) {
            Text(monthName)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Theme.primaryText)
            
            Text("\(year)")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.secondaryText)
        }
        .padding(.vertical, 20)
    }
    
    private func progressBar(title: String, amount: Double, total: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.primaryText)
                
                Spacer()
                
                Text("$\(Int(amount))")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Theme.cardBackground)
                        .frame(height: 16)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color)
                        .frame(width: total > 0 ? geometry.size.width * CGFloat(amount / total) : 0, height: 16)
                        .animation(.spring(response: 1.0), value: amount)
                }
            }
            .frame(height: 16)
        }
        .padding(20)
        .background(Theme.cardBackground.opacity(0.5))
        .cornerRadius(20)
    }
    
    private var netResultCard: some View {
        VStack(spacing: 12) {
            Text("Net Result")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.secondaryText)
            
            Text("$\(Int(viewModel.monthBalance))")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(viewModel.monthBalance >= 0 ? Theme.income : Theme.expense)
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("Income")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.secondaryText)
                    Text("$\(Int(viewModel.monthIncome))")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.income)
                }
                
                Rectangle()
                    .fill(Theme.secondaryText.opacity(0.3))
                    .frame(width: 1, height: 30)
                
                VStack(spacing: 4) {
                    Text("Expenses")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.secondaryText)
                    Text("$\(Int(viewModel.monthExpense))")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.expense)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Theme.cardBackground)
        .cornerRadius(24)
    }
    
    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Categories")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Theme.primaryText)
            
            ForEach(topCategories, id: \.category) { item in
                CategoryBreakdownRow(
                    category: item.category,
                    amount: item.amount,
                    percentage: item.percentage,
                    color: categoryColor(item.category)
                )
            }
        }
    }
    
    private var topCategories: [(category: String, amount: Double, percentage: Double)] {
        let expenseTransactions = viewModel.transactions.filter {
            $0.type == .expense &&
            Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month)
        }
        
        let grouped = Dictionary(grouping: expenseTransactions) { $0.category }
        let totals = grouped.mapValues { $0.reduce(0) { $0 + $1.amount } }
        let totalExpense = totals.values.reduce(0, +)
        
        return totals.map { (category: $0.key, amount: $0.value, percentage: totalExpense > 0 ? $0.value / totalExpense : 0) }
            .sorted { $0.amount > $1.amount }
            .prefix(5)
            .map { $0 }
    }
    
    private func categoryColor(_ categoryName: String) -> Color {
        viewModel.categories.first { $0.name == categoryName }?.color ?? Theme.neutral
    }
    
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date())
    }
    
    private var year: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: Date())
    }
}

struct CategoryBreakdownRow: View {
    let category: String
    let amount: Double
    let percentage: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(category)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.primaryText)
                
                Spacer()
                
                Text("$\(Int(amount))")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Theme.cardBackground)
                        .frame(height: 12)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(percentage), height: 12)
                        .animation(.spring(response: 0.8), value: percentage)
                }
            }
            .frame(height: 12)
        }
        .padding(16)
        .background(Theme.cardBackground.opacity(0.5))
        .cornerRadius(16)
    }
}
