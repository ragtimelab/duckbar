import SwiftUI
import AppKit

// MARK: - 주간 리포트 카드 뷰

struct WeeklyReportCardView: View {
    let report: WeeklyReport
    private let cardWidth: CGFloat = 360
    private let dayOrder = ["월", "화", "수", "목", "금", "토", "일"]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
            Divider().background(Color.primary.opacity(0.08))
            summarySection
            Divider().background(Color.primary.opacity(0.08))
            dailySection
            footerSection
        }
        .frame(width: cardWidth)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(nsColor: .windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Group {
                if let nsImage = Bundle.main.image(forResource: "duck_icon") {
                    Image(nsImage: nsImage).resizable().scaledToFit()
                } else {
                    Text("🦆").font(.system(size: 22))
                }
            }
            .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text("주간 리포트")
                    .font(.system(size: 15, weight: .bold))
                Text(weekRangeString)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("DuckBar")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Summary

    private var summarySection: some View {
        HStack(spacing: 0) {
            summaryBlock(
                title: "TOKENS",
                value: TokenUsage.formatTokens(report.totalTokens),
                delta: report.prevWeekTokens > 0 ? deltaString(report.tokenDelta, format: { TokenUsage.formatTokens(abs($0)) }) : nil,
                positive: report.tokenDelta >= 0
            )
            Divider().frame(width: 1).background(Color.primary.opacity(0.08))
            summaryBlock(
                title: "COST",
                value: TokenUsage.formatCost(report.totalCostUSD),
                delta: report.prevWeekCostUSD > 0 ? deltaStringDouble(report.costDelta, format: { TokenUsage.formatCost(abs($0)) }) : nil,
                positive: report.costDelta <= 0  // 비용은 줄면 긍정
            )
        }
    }

    private func summaryBlock(title: String, value: String, delta: String?, positive: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.secondary)
                .tracking(1.2)

            Text(value)
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundStyle(.primary)

            if let delta {
                Text(delta)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(positive ? Color.green : Color.red)
            } else {
                Text("첫 주간 데이터")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    // MARK: - Daily

    private var dailySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("요일별 사용량")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .tracking(1.2)
                Spacer()
                if !report.busiestDay.isEmpty {
                    HStack(spacing: 4) {
                        Text("최다")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                        Text("\(report.busiestDay)요일")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.orange)
                    }
                }
            }

            let maxTokens = dayOrder.compactMap { report.dailyTokens[$0] }.max() ?? 1
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(dayOrder, id: \.self) { day in
                    let tokens = report.dailyTokens[day] ?? 0
                    let ratio = maxTokens > 0 ? Double(tokens) / Double(maxTokens) : 0
                    let isBusiest = day == report.busiestDay

                    VStack(spacing: 4) {
                        if tokens > 0 {
                            Text(TokenUsage.formatTokens(tokens))
                                .font(.system(size: 7, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .fixedSize()
                        }
                        RoundedRectangle(cornerRadius: 3)
                            .fill(isBusiest ? Color.orange : Color.blue.opacity(0.5))
                            .frame(height: max(4, CGFloat(ratio) * 60))
                        Text(day)
                            .font(.system(size: 9, weight: isBusiest ? .semibold : .regular))
                            .foregroundStyle(isBusiest ? .orange : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 90)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            Spacer()
            Text("github.com/rofeels/duckbar")
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
        .padding(.bottom, 14)
    }

    // MARK: - Helpers

    private var weekRangeString: String {
        let cal = Calendar(identifier: .gregorian)
        let end = cal.date(byAdding: .day, value: 6, to: report.weekStart) ?? report.weekStart
        let f = DateFormatter()
        f.dateFormat = "M/d"
        f.timeZone = TimeZone(identifier: "Asia/Seoul")
        return "\(f.string(from: report.weekStart)) ~ \(f.string(from: end))"
    }

    private func deltaString(_ delta: Int, format: (Int) -> String) -> String {
        delta >= 0 ? "+\(format(delta))" : "-\(format(delta))"
    }

    private func deltaStringDouble(_ delta: Double, format: (Double) -> String) -> String {
        delta >= 0 ? "+\(format(delta))" : "-\(format(-delta))"
    }
}

// MARK: - 주간 리포트 윈도우 컨트롤러

@MainActor
final class WeeklyReportWindowController: NSWindowController {
    private let report: WeeklyReport

    init(report: WeeklyReport) {
        self.report = report

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 500),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "주간 리포트"
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)

        let contentView = WeeklyReportWindowView(report: report) { window.close() }
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

// MARK: - 주간 리포트 윈도우 뷰

struct WeeklyReportWindowView: View {
    let report: WeeklyReport
    let onClose: () -> Void
    @State private var copied = false
    @State private var saved = false
    @State private var colorScheme: ColorScheme? = nil

    var body: some View {
        VStack(spacing: 16) {
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

            WeeklyReportCardView(report: report)
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
        let view = WeeklyReportCardView(report: report)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0
        guard let image = renderer.nsImage else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([image])
        withAnimation { copied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { withAnimation { copied = false } }
    }

    private func saveCard() {
        let view = WeeklyReportCardView(report: report)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0
        guard let image = renderer.nsImage,
              let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:])
        else { return }

        let panel = NSSavePanel()
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        f.timeZone = TimeZone(identifier: "Asia/Seoul")
        panel.nameFieldStringValue = "duckbar-weekly-\(f.string(from: report.weekStart)).png"
        panel.allowedContentTypes = [.png]
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            try? pngData.write(to: url)
            withAnimation { saved = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { withAnimation { saved = false } }
        }
    }
}
