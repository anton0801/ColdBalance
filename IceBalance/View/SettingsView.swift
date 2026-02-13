import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: BalanceViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedCurrency = "$"
    @State private var startOfMonth = 1
    @State private var showingResetAlert = false
    
    let currencies = ["$", "€", "£", "¥", "₹", "₽"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background
                    .ignoresSafeArea()
                
                List {
                    Section {
                        Picker("Currency", selection: $selectedCurrency) {
                            ForEach(currencies, id: \.self) { currency in
                                Text(currency).tag(currency)
                            }
                        }
                        .foregroundColor(Theme.primaryText)
                        
                        Stepper("Start of Month: \(startOfMonth)", value: $startOfMonth, in: 1...28)
                            .foregroundColor(Theme.primaryText)
                    } header: {
                        Text("Preferences")
                            .foregroundColor(Theme.secondaryText)
                    }
                    
                    Section {
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "arrow.down.doc")
                                    .foregroundColor(Theme.neutral)
                                Text("Export Data")
                                    .foregroundColor(Theme.primaryText)
                            }
                        }
                    } header: {
                        Text("Data")
                            .foregroundColor(Theme.secondaryText)
                    }
                    
                    Section {
                        Button(action: { showingResetAlert = true }) {
                            HStack {
                                Image(systemName: "trash")
                                    .foregroundColor(Theme.expense)
                                Text("Reset All Data")
                                    .foregroundColor(Theme.expense)
                            }
                        }
                    }
                    
                    Section {
                        HStack {
                            Text("Version")
                                .foregroundColor(Theme.primaryText)
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(Theme.secondaryText)
                        }
                        
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "hand.raised")
                                    .foregroundColor(Theme.neutral)
                                Text("Privacy Policy")
                                    .foregroundColor(Theme.primaryText)
                            }
                        }
                    } header: {
                        Text("About")
                            .foregroundColor(Theme.secondaryText)
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .scrollContentBackground(.hidden)
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
                    Text("Settings")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Theme.primaryText)
                }
            }
            .alert(isPresented: $showingResetAlert) {
                Alert(
                    title: Text("Reset All Data"),
                    message: Text("This will delete all transactions and categories. This action cannot be undone."),
                    primaryButton: .destructive(Text("Reset")) {
                        // Implementation for reset
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}
