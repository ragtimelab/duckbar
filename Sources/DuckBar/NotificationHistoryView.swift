import SwiftUI

struct NotificationHistoryView: View {
    let onDone: () -> Void
    @State private var items: [NotificationHistoryItem] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Button(action: onDone) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Spacer()

                Text(L.history)
                    .font(.system(size: 13, weight: .semibold))

                Spacer()

                Button(action: {
                    NotificationHistoryManager.shared.clear()
                    items = []
                }) {
                    Text(L.historyClear)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()

            if items.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 20))
                        .foregroundStyle(.tertiary)
                    Text(L.historyEmpty)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(items) { item in
                            historyRow(item)
                            Divider()
                        }
                    }
                }
                .frame(maxHeight: 400)
            }
        }
        .onAppear {
            items = NotificationHistoryManager.shared.items
        }
    }

    private func historyRow(_ item: NotificationHistoryItem) -> some View {
        HStack(alignment: .top, spacing: 10) {
            // 타입 아이콘
            Image(systemName: iconName(for: item.type))
                .font(.system(size: 13))
                .foregroundStyle(iconColor(for: item.type))
                .frame(width: 20)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
                Text(item.body)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(relativeDate(item.date))
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    private func iconName(for type: NotificationHistoryItem.HistoryItemType) -> String {
        switch type {
        case .milestone: "trophy.fill"
        case .weeklyReport: "chart.bar.fill"
        case .usageAlert: "exclamationmark.triangle.fill"
        }
    }

    private func iconColor(for type: NotificationHistoryItem.HistoryItemType) -> Color {
        switch type {
        case .milestone: .orange
        case .weeklyReport: .blue
        case .usageAlert: .red
        }
    }

    private func relativeDate(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "방금 전" }
        if interval < 3600 { return "\(Int(interval / 60))분 전" }
        if interval < 86400 { return "\(Int(interval / 3600))시간 전" }
        let f = DateFormatter()
        f.dateFormat = "M/d HH:mm"
        f.timeZone = TimeZone(identifier: "Asia/Seoul")
        return f.string(from: date)
    }
}
