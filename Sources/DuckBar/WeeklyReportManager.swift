import Foundation
import UserNotifications

@MainActor
final class WeeklyReportManager {
    static let shared = WeeklyReportManager()

    private let lastReportKey = "weeklyReport_lastSentWeek"  // ISO 주차 "2026-W12"
    private let fm = FileManager.default

    // 앱 시작/갱신 시 호출 — 이번 주 월요일이 아직 리포트 안 보낸 주면 발송
    func checkAndSend(onReport: @escaping (WeeklyReport) -> Void) {
        let calendar = makeCalendar()
        let now = Date()

        // 오늘이 월요일이어야 발송
        guard calendar.component(.weekday, from: now) == 2 else { return }

        let weekKey = isoWeekKey(for: now)
        guard UserDefaults.standard.string(forKey: lastReportKey) != weekKey else { return }

        // 지난주 / 전전주 집계
        guard let lastMonday = lastWeekMonday(from: now, calendar: calendar),
              let prevMonday = calendar.date(byAdding: .weekOfYear, value: -1, to: lastMonday)
        else { return }

        let lastWeekEnd = calendar.date(byAdding: .day, value: 7, to: lastMonday)!
        let prevWeekEnd = lastMonday

        let lastWeek = loadWeekStats(from: lastMonday, to: lastWeekEnd, calendar: calendar)
        let prevWeek = loadWeekStats(from: prevMonday, to: prevWeekEnd, calendar: calendar)

        guard lastWeek.totalTokens > 0 else { return }  // 데이터 없으면 스킵

        var report = lastWeek
        report.weekStart = lastMonday
        report.prevWeekTokens = prevWeek.totalTokens
        report.prevWeekCostUSD = prevWeek.totalCostUSD

        UserDefaults.standard.set(weekKey, forKey: lastReportKey)
        sendNotification(report: report)
        let title = "📊 지난주 Claude 사용 리포트"
        let tokenStr = TokenUsage.formatTokens(report.totalTokens)
        let costStr = TokenUsage.formatCost(report.totalCostUSD)
        NotificationHistoryManager.shared.addWeeklyReport(
            title: title,
            body: "\(tokenStr) 토큰 · \(costStr) · \(report.weekStart.formatted(.dateTime.month().day()))주"
        )
        onReport(report)
    }

    private func loadWeekStats(from start: Date, to end: Date, calendar: Calendar) -> WeeklyReport {
        var report = WeeklyReport()
        var seenRequests = Set<String>()
        let dayNames = ["일", "월", "화", "수", "목", "금", "토"]
        var dailyTokens: [String: Int] = [:]

        let home = fm.homeDirectoryForCurrentUser
        let projectsDir = home.appendingPathComponent(".claude/projects")

        guard let projectDirs = try? fm.contentsOfDirectory(
            at: projectsDir, includingPropertiesForKeys: nil
        ) else { return report }

        for dir in projectDirs {
            guard let files = try? fm.contentsOfDirectory(
                at: dir, includingPropertiesForKeys: [.contentModificationDateKey]
            ) else { continue }

            for file in files where file.pathExtension == "jsonl" {
                if let attrs = try? file.resourceValues(forKeys: [.contentModificationDateKey]),
                   let modDate = attrs.contentModificationDate,
                   modDate < start { continue }

                guard let content = try? String(contentsOf: file, encoding: .utf8) else { continue }

                for line in content.components(separatedBy: .newlines) {
                    guard !line.isEmpty,
                          let lineData = line.data(using: .utf8),
                          let obj = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any],
                          obj["type"] as? String == "assistant",
                          let message = obj["message"] as? [String: Any],
                          let usage = message["usage"] as? [String: Any],
                          let tsStr = obj["timestamp"] as? String,
                          let ts = parseISO8601(tsStr),
                          ts >= start, ts < end
                    else { continue }

                    if let reqId = obj["requestId"] as? String {
                        if seenRequests.contains(reqId) { continue }
                        seenRequests.insert(reqId)
                    }

                    let input = usage["input_tokens"] as? Int ?? 0
                    let output = usage["output_tokens"] as? Int ?? 0
                    let cacheCreate = usage["cache_creation_input_tokens"] as? Int ?? 0
                    let cacheRead = usage["cache_read_input_tokens"] as? Int ?? 0
                    let tokens = input + output + cacheCreate + cacheRead
                    let cost = (Double(input) * 15.0
                        + Double(output) * 75.0
                        + Double(cacheCreate) * 18.75
                        + Double(cacheRead) * 1.50) / 1_000_000.0

                    report.totalTokens += tokens
                    report.totalCostUSD += cost

                    let weekday = calendar.component(.weekday, from: ts)
                    let dayName = dayNames[weekday - 1]
                    dailyTokens[dayName, default: 0] += tokens
                }
            }
        }

        report.dailyTokens = dailyTokens
        if let busiest = dailyTokens.max(by: { $0.value < $1.value }) {
            report.busiestDay = busiest.key
            report.busiestDayTokens = busiest.value
        }

        return report
    }

    private func sendNotification(report: WeeklyReport) {
        let content = UNMutableNotificationContent()
        content.title = "📊 지난주 Claude 사용 리포트"

        let tokenStr = TokenUsage.formatTokens(report.totalTokens)
        let costStr = TokenUsage.formatCost(report.totalCostUSD)
        let deltaSign = report.tokenDelta >= 0 ? "+" : ""
        let deltaStr = "\(deltaSign)\(TokenUsage.formatTokens(report.tokenDelta))"

        var body = "\(tokenStr) 토큰 · \(costStr)"
        if report.prevWeekTokens > 0 {
            body += " (전주 대비 \(deltaStr))"
        }
        if !report.busiestDay.isEmpty {
            body += " · 가장 활발한 날: \(report.busiestDay)요일"
        }

        content.body = body
        content.sound = .default
        content.userInfo = ["type": "weeklyReport"]

        let request = UNNotificationRequest(
            identifier: "duckbar_weekly_\(isoWeekKey(for: Date()))",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    // MARK: - Helpers

    private func makeCalendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Seoul")!
        cal.firstWeekday = 2  // 월요일 시작
        return cal
    }

    private func lastWeekMonday(from date: Date, calendar: Calendar) -> Date? {
        // 이번 주 월요일
        guard let thisMonday = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) else { return nil }
        // 지난주 월요일
        return calendar.date(byAdding: .weekOfYear, value: -1, to: thisMonday)
    }

    private func isoWeekKey(for date: Date) -> String {
        let cal = makeCalendar()
        let year = cal.component(.yearForWeekOfYear, from: date)
        let week = cal.component(.weekOfYear, from: date)
        return "\(year)-W\(String(format: "%02d", week))"
    }

    private func parseISO8601(_ str: String) -> Date? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: str) { return d }
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: str)
    }
}
