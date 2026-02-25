import SwiftUI
import SwiftUI
import WebKit

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


struct ColdWebView: View {
    @State private var target: String? = ""
    @State private var active = false
    
    var body: some View {
        ZStack {
            if active, let s = target, let url = URL(string: s) {
                WebCanvas(url: url).ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { boot() }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LoadTempURL"))) { _ in swap() }
    }
    
    private func boot() {
        let temp = UserDefaults.standard.string(forKey: "temp_url")
        let saved = UserDefaults.standard.string(forKey: "cb_endpoint_url") ?? ""
        target = temp ?? saved
        active = true
        if temp != nil { UserDefaults.standard.removeObject(forKey: "temp_url") }
    }
    
    private func swap() {
        if let temp = UserDefaults.standard.string(forKey: "temp_url"), !temp.isEmpty {
            active = false
            target = temp
            UserDefaults.standard.removeObject(forKey: "temp_url")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { active = true }
        }
    }
}

struct WebCanvas: UIViewRepresentable {
    let url: URL
    
    func makeCoordinator() -> WebAgent { WebAgent() }
    
    func makeUIView(context: Context) -> WKWebView {
        let w = buildView(agent: context.coordinator)
        context.coordinator.webView = w
        context.coordinator.visit(url, on: w)
        Task { await context.coordinator.restoreCookies(on: w) }
        return w
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    private func buildView(agent: WebAgent) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.processPool = WKProcessPool()
        let prefs = WKPreferences()
        prefs.javaScriptEnabled = true
        prefs.javaScriptCanOpenWindowsAutomatically = true
        cfg.preferences = prefs
        
        let ctrl = WKUserContentController()
        ctrl.addUserScript(WKUserScript(
            source: """
            (function(){
                const m=document.createElement('meta');
                m.name='viewport';m.content='width=device-width,initial-scale=1.0,maximum-scale=1.0,user-scalable=no';
                document.head.appendChild(m);
                const s=document.createElement('style');
                s.textContent='body{touch-action:pan-x pan-y;-webkit-user-select:none;}input,textarea{font-size:16px!important;}';
                document.head.appendChild(s);
                document.addEventListener('gesturestart',e=>e.preventDefault());
                document.addEventListener('gesturechange',e=>e.preventDefault());
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        ))
        cfg.userContentController = ctrl
        cfg.allowsInlineMediaPlayback = true
        cfg.mediaTypesRequiringUserActionForPlayback = []
        let pp = WKWebpagePreferences()
        pp.allowsContentJavaScript = true
        cfg.defaultWebpagePreferences = pp
        
        let w = WKWebView(frame: .zero, configuration: cfg)
        w.scrollView.minimumZoomScale = 1; w.scrollView.maximumZoomScale = 1
        w.scrollView.bounces = false; w.scrollView.bouncesZoom = false
        w.allowsBackForwardNavigationGestures = true
        w.scrollView.contentInsetAdjustmentBehavior = .never
        w.navigationDelegate = agent; w.uiDelegate = agent
        return w
    }
}

final class WebAgent: NSObject {
    weak var webView: WKWebView?
    private var hops = 0, maxHops = 70
    private var prev: URL?
    private var pin: URL?
    private var tabs: [WKWebView] = []
    private let jar = "cold_cookies"
    
    func visit(_ url: URL, on w: WKWebView) {
        print("❄️ [Cold] Visit: \(url)")
        hops = 0
        var r = URLRequest(url: url)
        r.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        w.load(r)
    }
    
    func restoreCookies(on w: WKWebView) async {
        guard let stored = UserDefaults.standard.object(forKey: jar)
                as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else { return }
        let store = w.configuration.websiteDataStore.httpCookieStore
        stored.values.flatMap { $0.values }
            .compactMap { HTTPCookie(properties: $0 as [HTTPCookiePropertyKey: Any]) }
            .forEach { store.setCookie($0) }
    }
    
    private func saveCookies(from w: WKWebView) {
        w.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self else { return }
            var data: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            for c in cookies {
                var d = data[c.domain] ?? [:]
                if let p = c.properties { d[c.name] = p }
                data[c.domain] = d
            }
            UserDefaults.standard.set(data, forKey: self.jar)
        }
    }
}

extension WebAgent: WKNavigationDelegate {
    func webView(_ w: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = action.request.url else { return decisionHandler(.allow) }
        prev = url
        let scheme = (url.scheme ?? "").lowercased()
        let path = url.absoluteString.lowercased()
        let ok: Set<String> = ["http","https","about","blob","data","javascript","file"]
        let special = ["srcdoc","about:blank","about:srcdoc"]
        if ok.contains(scheme) || special.contains(where: { path.hasPrefix($0) }) || path == "about:blank" {
            decisionHandler(.allow)
        } else {
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ w: WKWebView, didReceiveServerRedirectForProvisionalNavigation _: WKNavigation!) {
        hops += 1
        if hops > maxHops { w.stopLoading(); if let p = prev { w.load(URLRequest(url: p)) }; hops = 0; return }
        prev = w.url; saveCookies(from: w)
    }
    
    func webView(_ w: WKWebView, didCommit _: WKNavigation!) {
        if let u = w.url { pin = u; print("✅ [Cold] Commit: \(u)") }
    }
    
    func webView(_ w: WKWebView, didFinish _: WKNavigation!) {
        if let u = w.url { pin = u }; hops = 0; saveCookies(from: w)
    }
    
    func webView(_ w: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError error: Error) {
        if (error as NSError).code == NSURLErrorHTTPTooManyRedirects, let p = prev { w.load(URLRequest(url: p)) }
    }
    
    func webView(_ w: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

extension WebAgent: WKUIDelegate {
    func webView(_ w: WKWebView, createWebViewWith cfg: WKWebViewConfiguration, for action: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard action.targetFrame == nil else { return nil }
        let tab = WKWebView(frame: w.bounds, configuration: cfg)
        tab.navigationDelegate = self; tab.uiDelegate = self
        tab.allowsBackForwardNavigationGestures = true
        w.addSubview(tab)
        tab.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tab.topAnchor.constraint(equalTo: w.topAnchor),
            tab.bottomAnchor.constraint(equalTo: w.bottomAnchor),
            tab.leadingAnchor.constraint(equalTo: w.leadingAnchor),
            tab.trailingAnchor.constraint(equalTo: w.trailingAnchor)
        ])
        let g = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(closeTab(_:)))
        g.edges = .left; tab.addGestureRecognizer(g)
        tabs.append(tab)
        if let u = action.request.url, u.absoluteString != "about:blank" { tab.load(action.request) }
        return tab
    }
    
    @objc private func closeTab(_ g: UIScreenEdgePanGestureRecognizer) {
        guard g.state == .ended else { return }
        if let last = tabs.last { last.removeFromSuperview(); tabs.removeLast() } else { webView?.goBack() }
    }
    
    func webView(_ w: WKWebView, runJavaScriptAlertPanelWithMessage _: String, initiatedByFrame _: WKFrameInfo, completionHandler: @escaping () -> Void) { completionHandler() }
}
