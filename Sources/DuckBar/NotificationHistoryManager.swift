import Foundation

@MainActor
final class NotificationHistoryManager {
    static let shared = NotificationHistoryManager()

    private let key = "notificationHistory"
    private let maxItems = 50

    private(set) var items: [NotificationHistoryItem] = []

    private init() {
        load()
    }

    func add(_ item: NotificationHistoryItem) {
        items.insert(item, at: 0)
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }
        save()
    }

    func addMilestone(title: String, body: String) {
        add(NotificationHistoryItem(
            id: UUID().uuidString,
            type: .milestone,
            title: title,
            body: body,
            date: Date()
        ))
    }

    func addWeeklyReport(title: String, body: String) {
        add(NotificationHistoryItem(
            id: UUID().uuidString,
            type: .weeklyReport,
            title: title,
            body: body,
            date: Date()
        ))
    }

    func addUsageAlert(title: String, body: String) {
        add(NotificationHistoryItem(
            id: UUID().uuidString,
            type: .usageAlert,
            title: title,
            body: body,
            date: Date()
        ))
    }

    func clear() {
        items = []
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([NotificationHistoryItem].self, from: data)
        else { return }
        items = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
