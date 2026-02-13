import SwiftUI

struct TransactionsListView: View {
    @EnvironmentObject var viewModel: BalanceViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var groupedTransactions: [Date: [Transaction]] {
        Dictionary(grouping: viewModel.transactions) { transaction in
            Calendar.current.startOfDay(for: transaction.date)
        }
    }
    
    var sortedDates: [Date] {
        groupedTransactions.keys.sorted(by: >)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background
                    .ignoresSafeArea()
                
                if viewModel.transactions.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(sortedDates, id: \.self) { date in
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(formattedDate(date))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Theme.secondaryText)
                                        .padding(.horizontal, 20)
                                    
                                    ForEach(groupedTransactions[date] ?? []) { transaction in
                                        TransactionRow(transaction: transaction)
                                            .environmentObject(viewModel)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 20)
                    }
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
                    Text("Transactions")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Theme.primaryText)
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "snowflake")
                .font(.system(size: 60))
                .foregroundColor(Theme.neutral.opacity(0.5))
            
            Text("No Transactions Yet")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Theme.primaryText)
            
            Text("Add your first transaction to get started")
                .font(.system(size: 16))
                .foregroundColor(Theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    @EnvironmentObject var viewModel: BalanceViewModel
    @State private var showingDeleteAlert = false
    
    var category: Category? {
        viewModel.categories.first { $0.name == transaction.category }
    }
    
    var body: some View {
        Button(action: {
            showingDeleteAlert = true
        }) {
            HStack(spacing: 16) {
                // Category Icon
                ZStack {
                    Circle()
                        .fill(category?.color.opacity(0.2) ?? Theme.neutral.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: category?.icon ?? "tag.fill")
                        .font(.system(size: 20))
                        .foregroundColor(category?.color ?? Theme.neutral)
                }
                
                // Transaction Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.category)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.primaryText)
                    
                    if let note = transaction.note, !note.isEmpty {
                        Text(note)
                            .font(.system(size: 14))
                            .foregroundColor(Theme.secondaryText)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Amount
                Text("\(transaction.type == .income ? "+" : "-")$\(Int(transaction.amount))")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(transaction.type == .income ? Theme.income : Theme.expense)
            }
            .padding(16)
            .background(Theme.cardBackground)
            .cornerRadius(16)
            .padding(.horizontal, 20)
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Delete Transaction"),
                message: Text("Are you sure you want to delete this transaction?"),
                primaryButton: .destructive(Text("Delete")) {
                    viewModel.deleteTransaction(transaction)
                },
                secondaryButton: .cancel()
            )
        }
    }
}
