import Foundation
import UserNotifications

@MainActor
final class UsageAlertManager {
    static let shared = UsageAlertManager()

    private let cooldown: TimeInterval = 3600  // 60-minute cooldown / 60분 쿨다운
    private var firedThisSession = Set<String>()  // In-memory dedup per session / 세션 내 중복 방지

    // UserDefaults key format: "usageAlert_5h_50", "usageAlert_weekly_80"
    private func lastFiredKey(type: String, threshold: Int) -> String {
        "usageAlert_\(type)_\(threshold)"
    }

    func requestPermissionIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func check(rateLimits: RateLimits, thresholds: [Double]) {
        guard rateLimits.isLoaded else { return }
        let active = thresholds.filter { $0 > 0 }.sorted()
        guard !active.isEmpty else { return }

        checkThresholds(type: "5h", percent: rateLimits.fiveHourPercent, resetsAt: rateLimits.fiveHourResetsAt, thresholds: active)
        checkThresholds(type: "weekly", percent: rateLimits.weeklyPercent, resetsAt: rateLimits.weeklyResetsAt, thresholds: active)
    }

    private func checkThresholds(type: String, percent: Double, resetsAt: Date?, thresholds: [Double]) {
        // percent is already in 0–100 range / percent는 이미 0~100 범위
        // Iterate highest-first, fire only the highest reached threshold / 내림차순으로 가장 높은 임계값 하나만 발동
        for threshold in thresholds.reversed() {
            guard percent >= threshold else { continue }

            let key = lastFiredKey(type: type, threshold: Int(threshold))
            let lastFired = UserDefaults.standard.object(forKey: key) as? Date

            if let lastFired {
                let sinceLastFired = Date().timeIntervalSince(lastFired)
                if sinceLastFired < cooldown {
                    // Allow re-fire if a reset happened after last fire / 리셋 이후 재발동 허용
                    if let resetsAt, lastFired < resetsAt {
                        // First threshold hit after reset — allow / 리셋 이후 처음 도달 → 발동
                    } else {
                        break  // Still in cooldown / 쿨다운 중
                    }
                }
            }

            // Write to UserDefaults before firing to prevent duplicate fires on rapid successive calls
            // 빠른 연속 호출 시 중복 발동 방지를 위해 fire() 전에 기록
            let sessionKey = "\(type)_\(threshold)"
            guard !firedThisSession.contains(sessionKey) else { break }
            firedThisSession.insert(sessionKey)
            UserDefaults.standard.set(Date(), forKey: key)
            fire(type: type, threshold: Int(threshold), percent: percent, resetsAt: resetsAt)
            break
        }
    }

    private func fire(type: String, threshold: Int, percent: Double, resetsAt: Date?) {
        let typeLabel = type == "5h" ? "5시간" : "주간"
        let resetStr: String
        if let resetsAt {
            let remaining = resetsAt.timeIntervalSince(Date())
            if remaining > 0 {
                let h = Int(remaining / 3600)
                let m = Int(remaining.truncatingRemainder(dividingBy: 3600) / 60)
                resetStr = h > 0 ? " (리셋까지 \(h)h \(m)m)" : " (리셋까지 \(m)m)"
            } else {
                resetStr = ""
            }
        } else {
            resetStr = ""
        }

        let content = UNMutableNotificationContent()
        content.title = "Claude 사용량 \(threshold)% 도달"
        content.body = "\(typeLabel) 사용량이 \(String(format: "%.0f", percent))%에 도달했습니다.\(resetStr)"
        content.sound = .default

        // Fixed identifier per type+threshold prevents duplicate system notifications
        // type+threshold 고정 ID로 macOS 중복 알림 방지
        let request = UNNotificationRequest(
            identifier: "duckbar_usage_\(type)_\(threshold)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        NotificationHistoryManager.shared.addUsageAlert(
            title: content.title,
            body: content.body
        )
    }
}
