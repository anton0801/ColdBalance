import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0
    
    private let pages = [
        OnboardingPage(
            title: "Track your balance clearly",
            description: "See your financial health at a glance with intuitive visualizations",
            systemImage: "chart.line.uptrend.xyaxis",
            accentColor: Theme.neutral
        ),
        OnboardingPage(
            title: "Control income and expenses",
            description: "Easily manage transactions with smart categorization",
            systemImage: "arrow.up.arrow.down.circle.fill",
            accentColor: Theme.income
        ),
        OnboardingPage(
            title: "Keep your finances stable",
            description: "Build healthy financial habits with insights and tracking",
            systemImage: "drop.fill",
            accentColor: Theme.progress
        )
    ]
    
    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation {
                            hasCompletedOnboarding = true
                        }
                    }) {
                        Text("Skip")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Theme.secondaryText)
                    }
                    .padding()
                }
                
                Spacer()
                
                // Pages
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index], index: index, currentPage: $currentPage)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: 500)
                
                Spacer()
                
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(currentPage == index ? Theme.neutral : Theme.secondaryText.opacity(0.3))
                            .frame(width: currentPage == index ? 24 : 8, height: 8)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.bottom, 30)
                
                // Continue/Get Started button
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        withAnimation {
                            hasCompletedOnboarding = true
                        }
                    }
                }) {
                    Text(currentPage == pages.count - 1 ? "Get Started" : "Continue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Theme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.neutral)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let systemImage: String
    let accentColor: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    let index: Int
    @Binding var currentPage: Int
    @State private var appeared = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(page.accentColor.opacity(0.2))
                    .frame(width: 200, height: 200)
                    .scaleEffect(appeared ? 1.0 : 0.5)
                    .opacity(appeared ? 1.0 : 0)
                
                Image(systemName: page.systemImage)
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(page.accentColor)
                    .scaleEffect(appeared ? 1.0 : 0.3)
                    .rotationEffect(.degrees(appeared ? 0 : -180))
            }
            .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1), value: appeared)
            
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.primaryText)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1.0 : 0)
                    .offset(y: appeared ? 0 : 20)
                
                Text(page.description)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(Theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(appeared ? 1.0 : 0)
                    .offset(y: appeared ? 0 : 20)
            }
            .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3), value: appeared)
        }
        .padding()
        .onChange(of: currentPage) { newValue in
            if newValue == index {
                appeared = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    appeared = true
                }
            }
        }
        .onAppear {
            if currentPage == index {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    appeared = true
                }
            }
        }
    }
}
