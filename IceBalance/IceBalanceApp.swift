import SwiftUI
import Firebase
import FirebaseAuth

@main
struct IceBalanceApp: App {
    @StateObject private var balanceViewModel = BalanceViewModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showSplash = true
    
    init() {
        FirebaseApp.configure()
        Auth.auth().signInAnonymously()
        setupAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView()
                        .transition(.opacity)
                } else if !hasCompletedOnboarding {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                        .transition(.opacity)
                } else {
                    MainBalanceView()
                        .environmentObject(balanceViewModel)
                        .transition(.opacity)
                        .preferredColorScheme(.dark)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: showSplash)
            .animation(.easeInOut(duration: 0.5), value: hasCompletedOnboarding)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showSplash = false
                }
            }
        }
    }
    
    private func setupAppearance() {
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
        UINavigationBar.appearance().titleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
    }
}
