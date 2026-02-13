import SwiftUI

struct CategoriesView: View {
    @EnvironmentObject var viewModel: BalanceViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingAddCategory = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.categories) { category in
                            CategoryCard(category: category)
                                .environmentObject(viewModel)
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
                    Text("Categories")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Theme.primaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddCategory = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Theme.neutral)
                    }
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                AddCategoryView()
                    .environmentObject(viewModel)
            }
        }
    }
}

struct CategoryCard: View {
    let category: Category
    @EnvironmentObject var viewModel: BalanceViewModel
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: category.icon)
                    .font(.system(size: 24))
                    .foregroundColor(category.color)
            }
            
            Text(category.name)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.primaryText)
            
            Spacer()
            
            Button(action: { showingDeleteAlert = true }) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Theme.expense.opacity(0.7))
            }
        }
        .padding(20)
        .background(Theme.cardBackground)
        .cornerRadius(20)
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Delete Category"),
                message: Text("Are you sure? This cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    viewModel.deleteCategory(category)
                },
                secondaryButton: .cancel()
            )
        }
    }
}

struct AddCategoryView: View {
    @EnvironmentObject var viewModel: BalanceViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name = ""
    @State private var selectedColor = Theme.neutral
    @State private var selectedIcon = "tag.fill"
    
    let availableColors: [Color] = [
        Theme.income, Theme.expense, Theme.neutral, Theme.progress,
        Color(hex: "FFB84D"), Color(hex: "FF6B9D"), Color(hex: "A78BFA"),
        Color(hex: "34D399"), Color(hex: "F472B6"), Color(hex: "60A5FA")
    ]
    
    let availableIcons = [
        "tag.fill", "cart.fill", "car.fill", "house.fill", "airplane",
        "gift.fill", "heart.fill", "book.fill", "music.note", "gamecontroller.fill",
        "fork.knife", "cup.and.saucer.fill", "creditcard.fill", "banknote.fill"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Preview
                        categoryPreview
                        
                        // Name Input
                        nameInput
                        
                        // Color Picker
                        colorPicker
                        
                        // Icon Picker
                        iconPicker
                        
                        // Save Button
                        saveButton
                    }
                    .padding(20)
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
                    Text("New Category")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Theme.primaryText)
                }
            }
        }
    }
    
    private var categoryPreview: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(selectedColor.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Image(systemName: selectedIcon)
                    .font(.system(size: 40))
                    .foregroundColor(selectedColor)
            }
            
            Text(name.isEmpty ? "Category Name" : name)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Theme.primaryText)
        }
        .padding(.vertical, 20)
    }
    
    private var nameInput: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Name")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.primaryText)
            
            TextField("Enter category name", text: $name)
                .font(.system(size: 16))
                .foregroundColor(Theme.primaryText)
                .padding(16)
                .background(Theme.cardBackground)
                .cornerRadius(16)
        }
    }
    
    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Color")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.primaryText)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                ForEach(0..<availableColors.count, id: \.self) { index in
                    Circle()
                        .fill(availableColors[index])
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(Theme.primaryText, lineWidth: selectedColor == availableColors[index] ? 3 : 0)
                        )
                        .onTapGesture {
                            selectedColor = availableColors[index]
                        }
                }
            }
        }
    }
    
    private var iconPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Icon")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.primaryText)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                ForEach(availableIcons, id: \.self) { icon in
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedIcon == icon ? Theme.cardBackground : Theme.cardBackground.opacity(0.5))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: icon)
                            .font(.system(size: 24))
                            .foregroundColor(selectedIcon == icon ? selectedColor : Theme.secondaryText)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedColor, lineWidth: selectedIcon == icon ? 2 : 0)
                    )
                    .onTapGesture {
                        selectedIcon = icon
                    }
                }
            }
        }
    }
    
    private var saveButton: some View {
        Button(action: saveCategory) {
            Text("Create Category")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(name.isEmpty ? Theme.secondaryText.opacity(0.3) : Theme.neutral)
                .cornerRadius(16)
        }
        .disabled(name.isEmpty)
        .padding(.top, 20)
    }
    
    private func saveCategory() {
        viewModel.addCategory(
            name: name,
            colorHex: selectedColor.toHex() ?? "4FC3F7",
            icon: selectedIcon
        )
        presentationMode.wrappedValue.dismiss()
    }
}

extension Color {
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else { return nil }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "%02lX%02lX%02lX",
                     lroundf(r * 255),
                     lroundf(g * 255),
                     lroundf(b * 255))
    }
}
