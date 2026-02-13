import SwiftUI

struct MainBalanceView: View {
    @EnvironmentObject var viewModel: BalanceViewModel
    @State private var showingAddTransaction = false
    @State private var showingTransactionsList = false
    @State private var showingMonthlyOverview = false
    @State private var showingInsights = false
    @State private var showingSettings = false
    @State private var showingCategories = false
    @State private var selectedPeriod: Period = .month
    @State private var animatedBalance: Double = 0
    
    enum Period: String, CaseIterable {
        case today = "Today"
        case month = "Month"
    }
    
    var currentBalance: Double {
        selectedPeriod == .today ? viewModel.todayBalance : viewModel.monthBalance
    }
    
    var currentIncome: Double {
        selectedPeriod == .today ? viewModel.todayIncome : viewModel.monthIncome
    }
    
    var currentExpense: Double {
        selectedPeriod == .today ? viewModel.todayExpense : viewModel.monthExpense
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Period Toggle
                        periodToggle
                            .padding(.top, 20)
                        
                        // Balance Circle
                        balanceCircle
                        
                        // Quick Stats
                        quickStats
                        
                        // Action Buttons
                        actionButtons
                        
                        // Quick Actions Grid
                        quickActionsGrid
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: Theme.neutral))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Ice Balance")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.primaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Theme.neutral)
                    }
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView()
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $showingTransactionsList) {
                TransactionsListView()
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $showingMonthlyOverview) {
                MonthlyOverviewView()
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $showingInsights) {
                BalanceInsightsView()
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $showingCategories) {
                CategoriesView()
                    .environmentObject(viewModel)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            animateBalance()
        }
        .onChange(of: currentBalance) { _ in
            animateBalance()
        }
    }
    
    private var periodToggle: some View {
        HStack(spacing: 0) {
            ForEach(Period.allCases, id: \.self) { period in
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        selectedPeriod = period
                    }
                }) {
                    Text(period.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(selectedPeriod == period ? Theme.background : Theme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selectedPeriod == period ? Theme.neutral : Color.clear
                        )
                        .cornerRadius(12)
                }
            }
        }
        .padding(4)
        .background(Theme.cardBackground)
        .cornerRadius(16)
    }
    
    private var balanceCircle: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Theme.cardBackground, lineWidth: 20)
                .frame(width: 220, height: 220)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: progressValue)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [Theme.income, Theme.neutral, Theme.expense]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .frame(width: 220, height: 220)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 1.0, dampingFraction: 0.8), value: progressValue)
            
            // Balance text
            VStack(spacing: 8) {
                Text("$\(Int(animatedBalance))")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.primaryText)
                
                Text("Current Balance")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.secondaryText)
            }
        }
        .padding(.vertical, 30)
    }
    
    private var progressValue: CGFloat {
        let total = currentIncome + currentExpense
        guard total > 0 else { return 0.5 }
        return CGFloat(currentIncome / total)
    }
    
    private var quickStats: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Income",
                amount: currentIncome,
                color: Theme.income,
                icon: "arrow.down.circle.fill"
            )
            
            StatCard(
                title: "Expenses",
                amount: currentExpense,
                color: Theme.expense,
                icon: "arrow.up.circle.fill"
            )
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            ActionButton(
                title: "Add Income",
                icon: "plus.circle.fill",
                color: Theme.income
            ) {
                showingAddTransaction = true
            }
            
            ActionButton(
                title: "Add Expense",
                icon: "minus.circle.fill",
                color: Theme.expense
            ) {
                showingAddTransaction = true
            }
        }
    }
    
    private var quickActionsGrid: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                QuickActionCard(
                    title: "Transactions",
                    icon: "list.bullet.rectangle",
                    color: Theme.neutral
                ) {
                    showingTransactionsList = true
                }
                
                QuickActionCard(
                    title: "Categories",
                    icon: "square.grid.2x2",
                    color: Theme.progress
                ) {
                    showingCategories = true
                }
            }
            
            HStack(spacing: 16) {
                QuickActionCard(
                    title: "Overview",
                    icon: "chart.bar.fill",
                    color: Theme.income
                ) {
                    showingMonthlyOverview = true
                }
                
                QuickActionCard(
                    title: "Insights",
                    icon: "lightbulb.fill",
                    color: Theme.expense
                ) {
                    showingInsights = true
                }
            }
        }
    }
    
    private func animateBalance() {
        withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
            animatedBalance = currentBalance
        }
    }
}

struct StatCard: View {
    let title: String
    let amount: Double
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text("$\(Int(amount))")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(Theme.primaryText)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.secondaryText)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBackground)
        .cornerRadius(20)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let impactMed = UIImpactFeedbackGenerator(style: .medium)
            impactMed.impactOccurred()
            action()
        }) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color)
            .cornerRadius(16)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let impactMed = UIImpactFeedbackGenerator(style: .light)
            impactMed.impactOccurred()
            action()
        }) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(color)
                    .frame(height: 40)
                
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.primaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Theme.cardBackground)
            .cornerRadius(20)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
