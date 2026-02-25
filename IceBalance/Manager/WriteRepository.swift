import Foundation
import FirebaseDatabase
import AppsFlyerLib
import FirebaseCore
import FirebaseMessaging
import WebKit

protocol WriteRepository {
    func loadConfig() -> RestoredConfig
    func saveTracking(_ data: [String: String])
    func saveNavigation(_ data: [String: String])
    func saveEndpoint(_ url: String)
    func saveMode(_ mode: String)
    func savePermissions(_ state: PermissionState)
    func markLaunched()
    func validateFirebase() async throws -> Bool
    func fetchAttribution(deviceID: String) async throws -> [String: String]
    func fetchDestination(tracking: [String: String]) async throws -> String
}

final class DiskRepository: WriteRepository {
    
    private let vault = UserDefaults(suiteName: "group.cold.cache")!
    private let backup = UserDefaults.standard
    private var cache: [String: Any] = [:]
    
    // UNIQUE: cb_ prefix
    private enum K {
        static let tracking = "cb_tracking_data"
        static let navigation = "cb_navigation_data"
        static let endpoint = "cb_endpoint_url"
        static let mode = "cb_mode_state"
        static let launched = "cb_launched_flag"
        static let permApproved = "cb_perm_approved"
        static let permDeclined = "cb_perm_declined"
        static let permDate = "cb_perm_date"
    }
    
    init() {
        preheat()
    }
    
    // MARK: - Load
    
    func loadConfig() -> RestoredConfig {
        var tracking: [String: String] = [:]
        if let json = cache[K.tracking] as? String ?? vault.string(forKey: K.tracking),
           let dict = parseJSON(json) {
            tracking = dict
        }
        
        var navigation: [String: String] = [:]
        if let encoded = vault.string(forKey: K.navigation),
           let json = decode(encoded),
           let dict = parseJSON(json) {
            navigation = dict
        }
        
        let mode = vault.string(forKey: K.mode)
        let firstLaunch = !vault.bool(forKey: K.launched)
        
        let approved = vault.bool(forKey: K.permApproved)
        let declined = vault.bool(forKey: K.permDeclined)
        let ts = vault.double(forKey: K.permDate)
        let date = ts > 0 ? Date(timeIntervalSince1970: ts / 1000) : nil
        
        let permissions = PermissionState(
            approved: approved,
            declined: declined,
            lastAsked: date
        )
        
        return RestoredConfig(
            tracking: tracking,
            navigation: navigation,
            mode: mode,
            firstLaunch: firstLaunch,
            permissions: permissions
        )
    }
    
    // MARK: - Save
    
    func saveTracking(_ data: [String: String]) {
        if let json = toJSON(data) {
            vault.set(json, forKey: K.tracking)
            cache[K.tracking] = json
        }
    }
    
    func saveNavigation(_ data: [String: String]) {
        if let json = toJSON(data) {
            let encoded = encode(json)
            vault.set(encoded, forKey: K.navigation)
        }
    }
    
    func saveEndpoint(_ url: String) {
        vault.set(url, forKey: K.endpoint)
        backup.set(url, forKey: K.endpoint)
        cache[K.endpoint] = url
    }
    
    func saveMode(_ mode: String) {
        vault.set(mode, forKey: K.mode)
    }
    
    func savePermissions(_ state: PermissionState) {
        vault.set(state.approved, forKey: K.permApproved)
        vault.set(state.declined, forKey: K.permDeclined)
        if let date = state.lastAsked {
            vault.set(date.timeIntervalSince1970 * 1000, forKey: K.permDate)
        }
    }
    
    func markLaunched() {
        vault.set(true, forKey: K.launched)
    }
    
    // MARK: - Network
    
    private let session: URLSession = {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 30
        cfg.timeoutIntervalForResource = 90
        cfg.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        cfg.urlCache = nil
        return URLSession(configuration: cfg)
    }()
    
    func validateFirebase() async throws -> Bool {
        try await withCheckedThrowingContinuation { cont in
            Database.database().reference().child("users/log/data")
                .observeSingleEvent(of: .value) { snap in
                    if let s = snap.value as? String, !s.isEmpty, URL(string: s) != nil {
                        cont.resume(returning: true)
                    } else {
                        cont.resume(returning: false)
                    }
                } withCancel: { cont.resume(throwing: $0) }
        }
    }
    
    func fetchAttribution(deviceID: String) async throws -> [String: String] {
        var comps = URLComponents(string: "https://gcdsdk.appsflyer.com/install_data/v4.0/id\(ColdConfig.appID)")
        comps?.queryItems = [
            .init(name: "devkey", value: ColdConfig.devKey),
            .init(name: "device_id", value: deviceID)
        ]
        guard let url = comps?.url else { throw RepoError.badURL }
        
        var req = URLRequest(url: url)
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw RepoError.failed
        }
        guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw RepoError.decode
        }
        return dict.mapValues { "\($0)" }
    }
    
    private var ua: String = WKWebView().value(forKey: "userAgent") as? String ?? ""
    
    func fetchDestination(tracking: [String: String]) async throws -> String {
        guard let url = URL(string: "https://colldebalan.com/config.php") else {
            throw RepoError.badURL
        }
        
        var body: [String: Any] = tracking.mapValues { $0 as Any }
        body["os"] = "iOS"
        body["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        body["bundle_id"] = Bundle.main.bundleIdentifier ?? ""
        body["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID
        body["store_id"] = "id\(ColdConfig.appID)"
        body["push_token"] = UserDefaults.standard.string(forKey: "push_token") ?? Messaging.messaging().fcmToken
        body["locale"] = Locale.preferredLanguages.first.map { String($0.prefix(2)).uppercased() } ?? "EN"
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(ua, forHTTPHeaderField: "User-Agent")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // UNIQUE retry: [11, 22, 44]
        let delays: [Double] = [11.0, 22.0, 44.0]
        var last: Error?
        
        for (i, delay) in delays.enumerated() {
            do {
                let (data, resp) = try await session.data(for: req)
                guard let http = resp as? HTTPURLResponse else { throw RepoError.failed }
                
                if (200...299).contains(http.statusCode) {
                    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                          json["ok"] as? Bool == true,
                          let dest = json["url"] as? String else { throw RepoError.decode }
                    return dest
                } else if http.statusCode == 429 {
                    try await Task.sleep(nanoseconds: UInt64(delay * Double(i + 1) * 1_000_000_000))
                    continue
                } else {
                    throw RepoError.failed
                }
            } catch {
                last = error
                if i < delays.count - 1 {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        throw last ?? RepoError.failed
    }
    
    // MARK: - Helpers
    
    private func preheat() {
        if let v = vault.string(forKey: K.endpoint) { cache[K.endpoint] = v }
        if let v = vault.string(forKey: K.tracking) { cache[K.tracking] = v }
    }
    
    private func toJSON(_ d: [String: String]) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: d.mapValues { $0 as Any }),
              let s = String(data: data, encoding: .utf8) else { return nil }
        return s
    }
    
    private func parseJSON(_ s: String) -> [String: String]? {
        guard let data = s.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return dict.mapValues { "\($0)" }
    }
    
    // UNIQUE encoding: ! and ?
    private func encode(_ s: String) -> String {
        Data(s.utf8).base64EncodedString()
            .replacingOccurrences(of: "=", with: "!")
            .replacingOccurrences(of: "+", with: "?")
    }
    
    private func decode(_ s: String) -> String? {
        let b64 = s.replacingOccurrences(of: "!", with: "=")
                   .replacingOccurrences(of: "?", with: "+")
        guard let d = Data(base64Encoded: b64) else { return nil }
        return String(data: d, encoding: .utf8)
    }
}

enum RepoError: Error { case badURL, failed, decode }
