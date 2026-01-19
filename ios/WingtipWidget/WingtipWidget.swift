import WidgetKit
import SwiftUI

struct WidgetData: Codable {
    let totalCount: Int
    let lastScanDate: Int64
    let lastBookTitle: String
    let lastBookAuthor: String
    let lastBookCoverUrl: String
    let timestamp: Int64
}

struct Provider: TimelineProvider {
    let appGroupId = "group.com.ooheynerds.wingtip"
    let widgetDataKey = "widget_data"

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            totalCount: 0,
            lastBookTitle: "No books yet",
            lastBookAuthor: "",
            lastBookCoverUrl: nil,
            lastScanDate: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = loadEntry()
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }

    private func loadEntry() -> SimpleEntry {
        guard let userDefaults = UserDefaults(suiteName: appGroupId),
              let jsonString = userDefaults.string(forKey: widgetDataKey),
              let jsonData = jsonString.data(using: .utf8) else {
            return SimpleEntry(
                date: Date(),
                totalCount: 0,
                lastBookTitle: "Open Wingtip to scan",
                lastBookAuthor: "",
                lastBookCoverUrl: nil,
                lastScanDate: nil
            )
        }

        do {
            let widgetData = try JSONDecoder().decode(WidgetData.self, from: jsonData)
            let lastScanDate = widgetData.lastScanDate > 0 ? Date(timeIntervalSince1970: TimeInterval(widgetData.lastScanDate) / 1000.0) : nil

            return SimpleEntry(
                date: Date(),
                totalCount: widgetData.totalCount,
                lastBookTitle: widgetData.lastBookTitle.isEmpty ? "Last scan" : widgetData.lastBookTitle,
                lastBookAuthor: widgetData.lastBookAuthor,
                lastBookCoverUrl: widgetData.lastBookCoverUrl.isEmpty ? nil : widgetData.lastBookCoverUrl,
                lastScanDate: lastScanDate
            )
        } catch {
            print("[WingtipWidget] Error decoding widget data: \(error)")
            return SimpleEntry(
                date: Date(),
                totalCount: 0,
                lastBookTitle: "Error loading data",
                lastBookAuthor: "",
                lastBookCoverUrl: nil,
                lastScanDate: nil
            )
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let totalCount: Int
    let lastBookTitle: String
    let lastBookAuthor: String
    let lastBookCoverUrl: String?
    let lastScanDate: Date?
}

// MARK: - Small Widget View
struct WingtipWidgetSmallView : View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            // OLED Black background
            Color.black

            VStack(spacing: 8) {
                // Wingtip icon/branding
                Text("📚")
                    .font(.system(size: 32))

                // Count
                Text("\(entry.totalCount)")
                    .font(.system(size: 36, weight: .bold, design: .default))
                    .foregroundColor(.white)

                // Label
                Text("Books")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(red: 142/255, green: 142/255, blue: 147/255)) // Text Secondary
            }
            .padding()
        }
        .overlay(
            // 1px border (Swiss Utility design)
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color(red: 28/255, green: 28/255, blue: 30/255), lineWidth: 1)
        )
    }
}

// MARK: - Medium Widget View
struct WingtipWidgetMediumView : View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            // OLED Black background
            Color.black

            HStack(spacing: 12) {
                // Left side: Count
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(entry.totalCount)")
                        .font(.system(size: 48, weight: .bold, design: .default))
                        .foregroundColor(.white)

                    Text("Books Scanned")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 142/255, green: 142/255, blue: 147/255))

                    Spacer()

                    // Last scan date
                    if let lastScanDate = entry.lastScanDate {
                        Text("Last scan: \(lastScanDate, style: .relative) ago")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(Color(red: 142/255, green: 142/255, blue: 147/255))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                // Right side: Book cover or placeholder
                if let coverUrl = entry.lastBookCoverUrl, let url = URL(string: coverUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 120)
                                .clipped()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 0)
                                        .stroke(Color(red: 28/255, green: 28/255, blue: 30/255), lineWidth: 1)
                                )
                        case .failure(_):
                            bookPlaceholder
                        case .empty:
                            bookPlaceholder
                        @unknown default:
                            bookPlaceholder
                        }
                    }
                } else {
                    bookPlaceholder
                }
            }
            .padding()
        }
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color(red: 28/255, green: 28/255, blue: 30/255), lineWidth: 1)
        )
    }

    private var bookPlaceholder: some View {
        ZStack {
            Rectangle()
                .fill(Color(red: 28/255, green: 28/255, blue: 30/255))
                .frame(width: 80, height: 120)

            Text("📚")
                .font(.system(size: 40))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color(red: 28/255, green: 28/255, blue: 30/255), lineWidth: 1)
        )
    }
}

// MARK: - Widget Entry
struct WingtipWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            WingtipWidgetSmallView(entry: entry)
        case .systemMedium:
            WingtipWidgetMediumView(entry: entry)
        default:
            WingtipWidgetSmallView(entry: entry)
        }
    }
}

// MARK: - Widget Configuration
struct WingtipWidget: Widget {
    let kind: String = "WingtipWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WingtipWidgetEntryView(entry: entry)
                .widgetURL(URL(string: "wingtip://library"))
        }
        .configurationDisplayName("Library Stats")
        .description("View your scanned book count at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview
struct WingtipWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WingtipWidgetEntryView(entry: SimpleEntry(
                date: Date(),
                totalCount: 42,
                lastBookTitle: "The Great Gatsby",
                lastBookAuthor: "F. Scott Fitzgerald",
                lastBookCoverUrl: nil,
                lastScanDate: Date()
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))

            WingtipWidgetEntryView(entry: SimpleEntry(
                date: Date(),
                totalCount: 42,
                lastBookTitle: "The Great Gatsby",
                lastBookAuthor: "F. Scott Fitzgerald",
                lastBookCoverUrl: nil,
                lastScanDate: Date()
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
    }
}
