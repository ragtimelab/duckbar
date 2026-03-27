import SwiftUI
import AppKit

// MARK: - 공유 카드 미리보기 윈도우 컨트롤러

@MainActor
final class ShareCardWindowController: NSWindowController {
    private let stats: UsageStats
    private let chartTab: String
    private let provider: Provider

    init(stats: UsageStats, chartTab: String, provider: Provider = .claude) {
        self.stats = stats
        self.chartTab = chartTab
        self.provider = provider

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 600),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "공유 카드 미리보기"
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)

        let contentView = ShareCardWindowView(stats: stats, chartTab: chartTab, provider: provider) {
            window.close()
        }
        window.contentView = NSHostingView(rootView: contentView)
        window.setContentSize(window.contentView!.fittingSize)
    }

    required init?(coder: NSCoder) { fatalError() }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }
}

// MARK: - 미리보기 윈도우 뷰

struct ShareCardWindowView: View {
    let stats: UsageStats
    let onClose: () -> Void
    let provider: Provider

    @State private var currentChartTab: String
    @State private var colorScheme: ColorScheme? = nil
    @State private var copied = false
    @State private var saved = false

    init(stats: UsageStats, chartTab: String, provider: Provider = .claude, onClose: @escaping () -> Void) {
        self.stats = stats
        self.onClose = onClose
        self.provider = provider
        _currentChartTab = State(initialValue: chartTab)
    }

    var body: some View {
        VStack(spacing: 16) {
            // 차트 전환 탭 + 다크/라이트 토글
            HStack(spacing: 6) {
                SegmentButton(isSelected: currentChartTab == "line",
                              title: L.chartTabLine, fontSize: 11, padding: 5) {
                    currentChartTab = "line"
                }
                SegmentButton(isSelected: currentChartTab == "heatmap",
                              title: L.chartTabHeatmap, fontSize: 11, padding: 5) {
                    currentChartTab = "heatmap"
                }
                Spacer()
                // 다크/라이트 토글
                Button(action: {
                    if colorScheme == nil {
                        colorScheme = .dark
                    } else if colorScheme == .dark {
                        colorScheme = .light
                    } else {
                        colorScheme = nil
                    }
                }) {
                    Image(systemName: colorScheme == .dark ? "moon.fill" : colorScheme == .light ? "sun.max.fill" : "circle.lefthalf.filled")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(colorScheme == .dark ? "다크 모드" : colorScheme == .light ? "라이트 모드" : "시스템 모드")
            }

            // 카드 미리보기
            ShareCardView(stats: stats, chartTab: currentChartTab, provider: provider)
                .preferredColorScheme(colorScheme)
                .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 8)

            // 버튼
            HStack(spacing: 12) {
                Button(action: copyCard) {
                    HStack(spacing: 6) {
                        Image(systemName: copied ? "checkmark" : "doc.on.clipboard")
                        Text(copied ? L.shareCardCopied : L.shareCardCopy)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(copied ? Color.green : Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                Button(action: saveCard) {
                    HStack(spacing: 6) {
                        Image(systemName: saved ? "checkmark" : "square.and.arrow.down")
                        Text(saved ? L.shareCardSaved : L.shareCardSave)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.primary.opacity(0.1))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func copyCard() {
        copyShareCardToClipboard(stats: stats, chartTab: currentChartTab, provider: provider)
        withAnimation { copied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { copied = false }
        }
    }

    private func saveCard() {
        guard let image = renderShareCard(stats: stats, chartTab: currentChartTab, provider: provider),
              let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:])
        else { return }

        let panel = NSSavePanel()
        panel.nameFieldStringValue = "duckbar-\(saveDateString).png"
        panel.allowedContentTypes = [.png]
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            try? pngData.write(to: url)
            withAnimation { saved = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { saved = false }
            }
        }
    }

    private var saveDateString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd-HHmm"
        f.timeZone = TimeZone(identifier: "Asia/Seoul")
        return f.string(from: Date())
    }
}

// MARK: - Badge Share Card Window / 뱃지 공유 카드 윈도우

@MainActor
final class BadgeShareCardWindowController: NSWindowController {
    private let badges: [Badge]
    private let stats: UsageStats

    init(badges: [Badge], stats: UsageStats) {
        self.badges = badges
        self.stats = stats

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 500),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = L.badgesShareCard
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)

        let contentView = BadgeShareCardWindowView(badges: badges, stats: stats) {
            window.close()
        }
        window.contentView = NSHostingView(rootView: contentView)
        window.setContentSize(window.contentView!.fittingSize)
    }

    required init?(coder: NSCoder) { fatalError() }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }
}

struct BadgeShareCardWindowView: View {
    let badges: [Badge]
    let stats: UsageStats
    let onClose: () -> Void

    @State private var colorScheme: ColorScheme? = nil
    @State private var copied = false
    @State private var saved = false

    var body: some View {
        VStack(spacing: 16) {
            // Dark/light toggle / 다크/라이트 토글
            HStack {
                Spacer()
                Button(action: {
                    if colorScheme == nil { colorScheme = .dark }
                    else if colorScheme == .dark { colorScheme = .light }
                    else { colorScheme = nil }
                }) {
                    Image(systemName: colorScheme == .dark ? "moon.fill" : colorScheme == .light ? "sun.max.fill" : "circle.lefthalf.filled")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            BadgeShareCardView(badges: badges, stats: stats)
                .preferredColorScheme(colorScheme)
                .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 8)

            HStack(spacing: 12) {
                Button(action: copyCard) {
                    HStack(spacing: 6) {
                        Image(systemName: copied ? "checkmark" : "doc.on.clipboard")
                        Text(copied ? L.shareCardCopied : L.shareCardCopy)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(copied ? Color.green : Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                Button(action: saveCard) {
                    HStack(spacing: 6) {
                        Image(systemName: saved ? "checkmark" : "square.and.arrow.down")
                        Text(saved ? L.shareCardSaved : L.shareCardSave)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.primary.opacity(0.1))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func copyCard() {
        copyBadgeShareCardToClipboard(badges: badges, stats: stats)
        withAnimation { copied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { withAnimation { copied = false } }
    }

    private func saveCard() {
        guard let image = renderBadgeShareCard(badges: badges, stats: stats),
              let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:])
        else { return }

        let panel = NSSavePanel()
        panel.nameFieldStringValue = "duckbar-achievements.png"
        panel.allowedContentTypes = [.png]
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            try? pngData.write(to: url)
            withAnimation { saved = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { withAnimation { saved = false } }
        }
    }
}
