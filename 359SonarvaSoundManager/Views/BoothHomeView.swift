import SwiftUI

struct BoothHomeView: View {
    @EnvironmentObject private var store: DataStore
    @Binding var tab: Int
    @State private var boothStarted = Date()
    @State private var cueMoment: Moment?
    @State private var now = Date()

    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                NowPlayingBar(moment: store.latestMoment)

                boothHeader

                WaveformView(isLive: store.latestMoment != nil)

                quickPads

                cueCard

                recentCrate

                visualSpotlight
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .vinylCanvas()
        .toolbar(.hidden, for: .navigationBar)
        .onReceive(clock) { now = $0 }
        .sheet(item: $cueMoment) { moment in
            NavigationStack {
                MomentEditorView(existing: moment)
                    .environmentObject(store)
            }
        }
    }

    private var boothHeader: some View {
        HStack(alignment: .center, spacing: 16) {
            VinylDiscView(diameter: 118, isSpinning: store.latestMoment != nil)

            VStack(alignment: .leading, spacing: 10) {
                Text("SONARVA BOOTH")
                    .font(.caption2.weight(.bold))
                    .tracking(1.4)
                    .foregroundColor(Color("AppAccent"))
                metric(title: "Booth time", value: elapsedLabel)
                metric(title: "Streak", value: store.currentStreak == 0 ? "—" : "\(store.currentStreak)d")
                metric(title: "Spun today", value: "\(store.listensToday)")
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color("AppSurface"))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color("AppPrimary").opacity(0.35), lineWidth: 1)
        )
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2)
                .foregroundColor(Color("AppTextSecondary"))
            Text(value)
                .font(.headline)
                .foregroundColor(Color("AppTextPrimary"))
        }
    }

    private var elapsedLabel: String {
        let seconds = Int(now.timeIntervalSince(boothStarted))
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }

    private var quickPads: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                NavigationLink {
                    MomentEditorView(existing: nil)
                } label: {
                    DrumPadButton(title: "Capture", systemImage: "plus")
                }
                .buttonStyle(.plain)

                Button {
                    if let moment = store.latestMoment {
                        store.logListen(momentId: moment.id)
                    } else {
                        tab = 1
                    }
                } label: {
                    DrumPadButton(title: "Spin", systemImage: "play.fill")
                }
                .buttonStyle(.plain)
            }
            HStack(spacing: 10) {
                Button {
                    if let cue = store.tonightCue {
                        store.logListen(momentId: cue.id)
                        cueMoment = store.moment(id: cue.id)
                    } else {
                        tab = 1
                    }
                } label: {
                    DrumPadButton(title: "Tonight", systemImage: "shuffle")
                }
                .buttonStyle(.plain)

                Button {
                    tab = 4
                } label: {
                    DrumPadButton(title: "Pulse", systemImage: "chart.bar.fill")
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var cueCard: some View {
        if let cue = store.tonightCue {
            Button {
                cueMoment = cue
            } label: {
                StudioCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TONIGHT'S CUE")
                            .font(.caption2.weight(.bold))
                            .tracking(1.3)
                            .foregroundColor(Color("AppAccent"))
                        Text("\(cue.emoji)  \(cue.songTitle)")
                            .font(.headline)
                            .foregroundColor(Color("AppTextPrimary"))
                        Text(cue.artistName.isEmpty ? "Unknown artist" : cue.artistName)
                            .font(.subheadline)
                            .foregroundColor(Color("AppTextSecondary"))
                        HStack {
                            MoodChip(mood: cue.mood, compact: true)
                            Text(cue.listenCount == 0 ? "Never spun" : "Waiting longest in the crate")
                                .font(.caption)
                                .foregroundColor(Color("AppTextSecondary"))
                        }
                    }
                }
            }
            .buttonStyle(.plain)
        } else {
            StudioCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("TONIGHT'S CUE")
                        .font(.caption2.weight(.bold))
                        .tracking(1.3)
                        .foregroundColor(Color("AppAccent"))
                    Text("The crate is empty. Capture a cassette and the booth will start cuing tracks.")
                        .font(.subheadline)
                        .foregroundColor(Color("AppTextSecondary"))
                }
            }
        }
    }

    @ViewBuilder
    private var recentCrate: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("RECENT CRATE")
                    .font(.caption2.weight(.bold))
                    .tracking(1.3)
                    .foregroundColor(Color("AppAccent"))
                Spacer()
                Button("See all") { tab = 1 }
                    .font(.caption.weight(.bold))
                    .foregroundColor(Color("AppPrimary"))
            }
            if store.sortedMoments.isEmpty {
                EmptyStateView(systemImage: "opticaldisc", message: "No cassettes in the booth yet.")
            } else {
                ForEach(Array(store.sortedMoments.prefix(4))) { moment in
                    NavigationLink {
                        MomentEditorView(existing: moment)
                    } label: {
                        CassetteCard(moment: moment)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var visualSpotlight: some View {
        let collection = spotlightCollection
        VStack(alignment: .leading, spacing: 10) {
            Text("VISUAL SPOTLIGHT")
                .font(.caption2.weight(.bold))
                .tracking(1.3)
                .foregroundColor(Color("AppAccent"))
            NavigationLink {
                VisualDetailView(collection: collection)
            } label: {
                VStack(alignment: .leading, spacing: 0) {
                    Image(collection.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 128)
                        .clipped()
                    VStack(alignment: .leading, spacing: 4) {
                        Text(collection.title)
                            .font(.headline)
                            .foregroundColor(Color("AppTextPrimary"))
                        Text(collection.subtitle)
                            .font(.caption)
                            .foregroundColor(Color("AppTextSecondary"))
                    }
                    .padding(12)
                }
                .background(Color("AppSurface"))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color("AppPrimary").opacity(0.35), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var spotlightCollection: VisualCollection {
        if let favourite = store.favouriteCollections.first {
            return favourite
        }
        let index = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return VisualCollection.catalog[index % VisualCollection.catalog.count]
    }
}
