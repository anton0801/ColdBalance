import SwiftUI
import Firebase
import FirebaseAuth
import AppTrackingTransparency
import AppsFlyerLib

final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        Auth.auth().signInAnonymously()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didActivate), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        return true
    }
    
    @objc private func didActivate() {
        if #available(iOS 14, *) {
            // AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    // AppsFlyerLib.shared().start()
                    UserDefaults.standard.set(status.rawValue, forKey: "att_status")
                }
            }
        } else {
            // AppsFlyerLib.shared().start()
        }
    }
    
}

@main
struct IceBalanceApp: App {
    
    @StateObject private var balanceViewModel = BalanceViewModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showSplash = true
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
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
