import SwiftUI

struct SplashView: View {
    @State private var snowflakes: [Snowflake] = []
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var circleScale: CGFloat = 0.95
    
    var body: some View {
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
        }
        .onAppear {
            generateSnowflakes()
            animateLogo()
        }
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
