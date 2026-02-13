import SwiftUI

struct AddTransactionView: View {
    @EnvironmentObject var viewModel: BalanceViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedType: TransactionType = .expense
    @State private var amount: String = ""
    @State private var selectedCategory: String = ""
    @State private var selectedDate = Date()
    @State private var note: String = ""
    @State private var showingDatePicker = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Type Selector
                        typeSelector
                            .padding(.top, 20)
                        
                        // Amount Input
                        amountInput
                        
                        // Category Selector
                        categorySelector
                        
                        // Date Picker
                        datePicker
                        
                        // Note Input
                        noteInput
                        
                        // Save Button
                        saveButton
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Theme.secondaryText)
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Add Transaction")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Theme.primaryText)
                }
            }
        }
    }
    
    private var typeSelector: some View {
        HStack(spacing: 0) {
            ForEach([TransactionType.income, TransactionType.expense], id: \.self) { type in
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        selectedType = type
                    }
                }) {
                    HStack {
                        Image(systemName: type == .income ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                            .font(.system(size: 20))
                        
                        Text(type == .income ? "Income" : "Expense")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(selectedType == type ? .white : Theme.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        selectedType == type ? (type == .income ? Theme.income : Theme.expense) : Color.clear
                    )
                    .cornerRadius(14)
                }
            }
        }
        .padding(4)
        .background(Theme.cardBackground)
        .cornerRadius(18)
    }
    
    private var amountInput: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Amount")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.primaryText)
            
            HStack {
                Text("$")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.secondaryText)
                
                TextField("0", text: $amount)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.primaryText)
                    .keyboardType(.decimalPad)
            }
            .padding(20)
            .background(Theme.cardBackground)
            .cornerRadius(20)
        }
    }
    
    private var categorySelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.primaryText)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.categories) { category in
                        CategoryChip(
                            category: category,
                            isSelected: selectedCategory == category.name
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedCategory = category.name
                            }
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
    
    private var datePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Date")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.primaryText)
            
            Button(action: { showingDatePicker.toggle() }) {
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.neutral)
                    
                    Text(selectedDate, style: .date)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.primaryText)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.secondaryText)
                }
                .padding(20)
                .background(Theme.cardBackground)
                .cornerRadius(20)
            }
            
            if showingDatePicker {
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .accentColor(Theme.neutral)
                    .padding()
                    .background(Theme.cardBackground)
                    .cornerRadius(20)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4), value: showingDatePicker)
    }
    
    private var noteInput: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Note (Optional)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.primaryText)
            
            TextField("Add a note...", text: $note)
                .font(.system(size: 16))
                .foregroundColor(Theme.primaryText)
                .padding(20)
                .background(Theme.cardBackground)
                .cornerRadius(20)
        }
    }
    
    private var saveButton: some View {
        Button(action: saveTransaction) {
            Text("Save Transaction")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    isFormValid ? Theme.neutral : Theme.secondaryText.opacity(0.3)
                )
                .cornerRadius(20)
        }
        .disabled(!isFormValid)
        .padding(.top, 20)
    }
    
    private var isFormValid: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else { return false }
        return !selectedCategory.isEmpty
    }
    
    private func saveTransaction() {
        guard let amountValue = Double(amount) else { return }
        
        let impactMed = UIImpactFeedbackGenerator(style: .medium)
        impactMed.impactOccurred()
        
        viewModel.addTransaction(
            type: selectedType,
            amount: amountValue,
            category: selectedCategory,
            date: selectedDate,
            note: note.isEmpty ? nil : note
        )
        
        presentationMode.wrappedValue.dismiss()
    }
}

struct CategoryChip: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 16))
                
                Text(category.name)
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : Theme.primaryText)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                isSelected ? category.color : Theme.cardBackground
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(category.color, lineWidth: isSelected ? 0 : 2)
            )
        }
    }
}
