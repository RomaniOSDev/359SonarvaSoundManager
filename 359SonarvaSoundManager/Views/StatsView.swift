import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject private var store: DataStore
    @State private var range = 7

    private var dayPoints: [(day: Date, count: Int)] {
        store.dailyListenCounts(days: range)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    statTile(title: "Cassettes", value: "\(store.moments.count)", symbol: "opticaldisc")
                    statTile(title: "Memos", value: "\(store.memos.count)", symbol: "mic.fill")
                    statTile(title: "Spins", value: "\(store.listenLogs.count)", symbol: "play.circle.fill")
                    statTile(title: "Streak", value: store.currentStreak == 0 ? "0" : "\(store.currentStreak)d", symbol: "flame.fill")
                }

                Picker("Range", selection: $range) {
                    Text("7 days").tag(7)
                    Text("14 days").tag(14)
                    Text("30 days").tag(30)
                }
                .pickerStyle(.segmented)
                .colorScheme(.dark)

                chartCard(title: "LISTENING PULSE") {
                    if store.listenLogs.isEmpty {
                        emptyChart("Spin a cassette to start the pulse.")
                    } else {
                        Chart(dayPoints, id: \.day) { point in
                            BarMark(
                                x: .value("Day", point.day, unit: .day),
                                y: .value("Spins", point.count)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color("AppPrimary"), Color("AppAccent")],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day, count: max(range / 7, 1))) { _ in
                                AxisGridLine().foregroundStyle(Color("AppTextSecondary").opacity(0.18))
                                AxisValueLabel(format: .dateTime.weekday(.narrow))
                                    .foregroundStyle(Color("AppTextSecondary"))
                            }
                        }
                        .chartYAxis {
                            AxisMarks { _ in
                                AxisGridLine().foregroundStyle(Color("AppTextSecondary").opacity(0.18))
                                AxisValueLabel().foregroundStyle(Color("AppTextSecondary"))
                            }
                        }
                        .frame(height: 180)
                    }
                }

                chartCard(title: "MOOD MIX") {
                    let moods = store.moodCounts().filter { $0.count > 0 }
                    if moods.isEmpty {
                        emptyChart("Tag a mood on a cassette to see the mix.")
                    } else {
                        Chart(moods, id: \.mood) { item in
                            BarMark(
                                x: .value("Count", item.count),
                                y: .value("Mood", item.mood.title)
                            )
                            .foregroundStyle(Color("AppPrimary"))
                        }
                        .chartXAxis {
                            AxisMarks { _ in
                                AxisGridLine().foregroundStyle(Color("AppTextSecondary").opacity(0.18))
                                AxisValueLabel().foregroundStyle(Color("AppTextSecondary"))
                            }
                        }
                        .chartYAxis {
                            AxisMarks { _ in
                                AxisValueLabel().foregroundStyle(Color("AppTextPrimary"))
                            }
                        }
                        .frame(height: CGFloat(max(moods.count, 3)) * 36)
                    }
                }

                chartCard(title: "MEMO CADENCE") {
                    let points = store.memoDailyCounts(days: range)
                    if store.memos.isEmpty {
                        emptyChart("Sleeve notes will plot here as you write them.")
                    } else {
                        Chart(points, id: \.day) { point in
                            LineMark(
                                x: .value("Day", point.day, unit: .day),
                                y: .value("Memos", point.count)
                            )
                            .foregroundStyle(Color("AppAccent"))
                            .interpolationMethod(.catmullRom)
                            AreaMark(
                                x: .value("Day", point.day, unit: .day),
                                y: .value("Memos", point.count)
                            )
                            .foregroundStyle(Color("AppAccent").opacity(0.18))
                            .interpolationMethod(.catmullRom)
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day, count: max(range / 7, 1))) { _ in
                                AxisGridLine().foregroundStyle(Color("AppTextSecondary").opacity(0.18))
                                AxisValueLabel(format: .dateTime.weekday(.narrow))
                                    .foregroundStyle(Color("AppTextSecondary"))
                            }
                        }
                        .chartYAxis {
                            AxisMarks { _ in
                                AxisGridLine().foregroundStyle(Color("AppTextSecondary").opacity(0.18))
                                AxisValueLabel().foregroundStyle(Color("AppTextSecondary"))
                            }
                        }
                        .frame(height: 160)
                    }
                }

                if let most = store.mostSpun, most.listenCount > 0 {
                    StudioCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("MOST SPUN")
                                .font(.caption2.weight(.bold))
                                .tracking(1.3)
                                .foregroundColor(Color("AppAccent"))
                            Text("\(most.emoji)  \(most.songTitle)")
                                .font(.headline)
                                .foregroundColor(Color("AppTextPrimary"))
                            Text("\(most.listenCount) spins · \(most.mood.title)")
                                .font(.subheadline)
                                .foregroundColor(Color("AppTextSecondary"))
                        }
                    }
                }

                if !store.topArtists.isEmpty {
                    StudioCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("TOP ARTISTS")
                                .font(.caption2.weight(.bold))
                                .tracking(1.3)
                                .foregroundColor(Color("AppAccent"))
                            ForEach(Array(store.topArtists.prefix(5).enumerated()), id: \.offset) { index, artist in
                                HStack {
                                    Text("\(index + 1)")
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(Color("AppAccent"))
                                        .frame(width: 18)
                                    Text(artist.name)
                                        .foregroundColor(Color("AppTextPrimary"))
                                    Spacer()
                                    Text("\(artist.count)")
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(Color("AppTextSecondary"))
                                }
                            }
                        }
                    }
                }
            }
            .padding(18)
        }
        .vinylCanvas()
        .navigationTitle("Pulse")
        .studioNavChrome()
    }

    private func statTile(title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .foregroundColor(Color("AppAccent"))
            Text(value)
                .font(.title.weight(.bold))
                .foregroundColor(Color("AppTextPrimary"))
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(Color("AppTextSecondary"))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("AppSurface"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color("AppPrimary").opacity(0.3), lineWidth: 1)
        )
    }

    private func chartCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        StudioCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.caption2.weight(.bold))
                    .tracking(1.3)
                    .foregroundColor(Color("AppAccent"))
                content()
            }
        }
    }

    private func emptyChart(_ message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundColor(Color("AppTextSecondary"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 18)
    }
}
