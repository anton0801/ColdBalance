import SwiftUI
import Combine

struct SplashView: View {
    @State private var snowflakes: [Snowflake] = []
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var circleScale: CGFloat = 0.95
    
    @StateObject private var engine = CQRSEngine()
    @State private var streams = Set<AnyCancellable>()
    
    private func setupStreams() {
        NotificationCenter.default.publisher(for: Notification.Name("ConversionDataReceived"))
            .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
            .map { $0.mapValues { "\($0)" } }
            .sink { engine.execute(.ingestTracking($0)) }
            .store(in: &streams)
        
        NotificationCenter.default.publisher(for: Notification.Name("deeplink_values"))
            .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
            .map { $0.mapValues { "\($0)" } }
            .sink { engine.execute(.ingestNavigation($0)) }
            .store(in: &streams)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background
                    .ignoresSafeArea()
                
                // Animated snowflakes
                ForEach(snowflakes) { flake in
                    Image(systemName: "sparkle")
                        .font(.system(size: flake.size))
                        .foregroundColor(Theme.progress.opacity(flake.opacity))
                        .position(x: flake.x, y: flake.y)
                        .animation(
                            Animation.linear(duration: flake.duration)
                                .repeatForever(autoreverses: false),
                            value: flake.y
                        )
                }
                
                VStack(spacing: 20) {
                    // Logo circle with balance line
                    ZStack {
                        Circle()
                            .fill(Theme.balanceGradient)
                            .frame(width: 120, height: 120)
                            .scaleEffect(circleScale)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                                value: circleScale
                            )
                        
                        Rectangle()
                            .fill(Theme.primaryText)
                            .frame(width: 60, height: 3)
                            .cornerRadius(1.5)
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    
                    // App name
                    VStack(spacing: 4) {
                        Text("Cold Balance")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.primaryText)
                        
                        Text("Keep Your Finances Stable")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.secondaryText)
                    }
                    .opacity(logoOpacity)
                }
                
                NavigationLink(
                    destination: ColdWebView().navigationBarBackButtonHidden(true),
                    isActive: $engine.navigateToWeb
                ) { EmptyView() }

                NavigationLink(
                    destination: RootView().navigationBarBackButtonHidden(true),
                    isActive: $engine.navigateToMain
                ) { EmptyView() }
            }
            .onAppear {
                generateSnowflakes()
                animateLogo()
                engine.execute(.initialize)
                setupStreams()
            }
            .fullScreenCover(isPresented: $engine.showPermissionSheet) {
                ColdPermissionView(engine: engine)
            }
            .fullScreenCover(isPresented: $engine.showOfflineView) {
                UnavailableView()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func generateSnowflakes() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        for _ in 0..<30 {
            let flake = Snowflake(
                x: CGFloat.random(in: 0...screenWidth),
                y: CGFloat.random(in: -100...screenHeight),
                size: CGFloat.random(in: 8...20),
                duration: Double.random(in: 3...6),
                opacity: Double.random(in: 0.3...0.8)
            )
            snowflakes.append(flake)
        }
        
        // Animate snowflakes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            for i in snowflakes.indices {
                snowflakes[i].y = screenHeight + 100
            }
        }
    }
    
    private func animateLogo() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            circleScale = 1.0
        }
    }
}

struct Snowflake: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let size: CGFloat
    let duration: Double
    let opacity: Double
}

struct UnavailableView: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image(geo.size.width > geo.size.height ? "issues_bg_screen_landscape" : "issues_bg_screen")
                    .resizable().scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .ignoresSafeArea().opacity(0.9)
                
                Image("alert_issue")
                    .resizable()
                    .frame(width: 300, height: 260)
            }
        }
        .ignoresSafeArea()
    }
}

struct ColdPermissionView: View {
    @ObservedObject var engine: CQRSEngine
    
    var body: some View {
        GeometryReader { g in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image(g.size.width > g.size.height ? "notifications_bg_screen_landscape" : "notifications_bg_screen")
                    .resizable().scaledToFill()
                    .frame(width: g.size.width, height: g.size.height)
                    .ignoresSafeArea().opacity(0.9)
                
                if g.size.width < g.size.height {
                    VStack(spacing: 12) {
                        Spacer()
                        titleText
                        subtitleText
                        actionButtons
                    }.padding(.bottom, 24)
                } else {
                    HStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 12) { Spacer(); titleText2; subtitleText2 }
                        Spacer()
                        VStack { Spacer(); actionButtons }
                        Spacer()
                    }.padding(.bottom, 24)
                }
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
    
    private var titleText: some View {
        Text("ALLOW NOTIFICATIONS ABOUT\nBONUSES AND PROMOS")
            .font(.custom("Lalezar-Regular", size: 25))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .multilineTextAlignment(.center)
    }
    
    private var subtitleText: some View {
        Text("STAY TUNED WITH BEST OFFERS FROM\nOUR CASINO")
            .font(.custom("Lalezar-Regular", size: 17))
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 12)
            .multilineTextAlignment(.center)
    }
    
    private var titleText2: some View {
        Text("ALLOW NOTIFICATIONS ABOUT\nBONUSES AND PROMOS")
            .font(.custom("Lalezar-Regular", size: 25))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .multilineTextAlignment(.leading)
    }
    
    private var subtitleText2: some View {
        Text("STAY TUNED WITH BEST OFFERS FROM\nOUR CASINO")
            .font(.custom("Lalezar-Regular", size: 17))
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 12)
            .multilineTextAlignment(.leading)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 20) {
            Button {
                engine.execute(.requestNotificationPermission)
            } label: {
                Image("notifications_screen_btn").resizable().frame(width: 300, height: 55)
            }
            
            Button {
                engine.execute(.deferNotifications)
            } label: {
                Text("Skip")
                    .font(.custom("Knewave-Regular", size: 12))
                    .foregroundColor(.white)
            }
            .frame(height: 40)
        }
    }
}
