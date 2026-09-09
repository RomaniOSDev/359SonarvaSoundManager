import Foundation

struct VisualCollection: Identifiable, Hashable {
    let id: UUID
    let title: String
    let subtitle: String
    let imageName: String
    let cueNotes: [String]
    let suggestedMood: ListeningMood

    static let catalog: [VisualCollection] = [
        VisualCollection(
            id: UUID(uuidString: "A11C0001-0000-4000-8000-000000000001")!,
            title: "Night Listening",
            subtitle: "Headphones after midnight",
            imageName: "tile_headphones",
            cueNotes: [
                "Keep the room dim and the volume honest.",
                "Let one record loop while the city hushes.",
                "Write what the bass does to the quiet."
            ],
            suggestedMood: .night
        ),
        VisualCollection(
            id: UUID(uuidString: "A11C0001-0000-4000-8000-000000000002")!,
            title: "Live Glow",
            subtitle: "Magenta wash over a packed floor",
            imageName: "banner_concert",
            cueNotes: [
                "Remember the first chorus when the lights snapped.",
                "Crowd noise is part of the mix — keep it.",
                "Pin the moment the singer leaned into the neon."
            ],
            suggestedMood: .live
        ),
        VisualCollection(
            id: UUID(uuidString: "A11C0001-0000-4000-8000-000000000003")!,
            title: "Studio Desk",
            subtitle: "Synths, cables, and a warm lamp",
            imageName: "tile_synth",
            cueNotes: [
                "Patch one sound and stay with it longer than usual.",
                "Leave the metronome off for a take.",
                "Photograph the desk only in your head — then caption it."
            ],
            suggestedMood: .focus
        ),
        VisualCollection(
            id: UUID(uuidString: "A11C0001-0000-4000-8000-000000000004")!,
            title: "Dawn Commute",
            subtitle: "Low-volume focus before the city wakes",
            imageName: "tile_headphones",
            cueNotes: [
                "One album, no skip, window seat if you can.",
                "Note the track that matches the first light.",
                "Keep the mix dry — no extra caffeine in the EQ."
            ],
            suggestedMood: .chill
        ),
        VisualCollection(
            id: UUID(uuidString: "A11C0001-0000-4000-8000-000000000005")!,
            title: "Peak Hour",
            subtitle: "Kick drums and a neon ceiling",
            imageName: "banner_concert",
            cueNotes: [
                "Log the drop you replayed three times.",
                "Stand up for the chorus even at the desk.",
                "Write the lyric that punched through the room."
            ],
            suggestedMood: .hype
        ),
        VisualCollection(
            id: UUID(uuidString: "A11C0001-0000-4000-8000-000000000006")!,
            title: "Rain Booth",
            subtitle: "Grey window, slow reverb, one lamp",
            imageName: "tile_synth",
            cueNotes: [
                "Let a ballad take the whole side of the tape.",
                "Describe the weather in the sleeve notes.",
                "Do not fill the silence — it belongs on the record."
            ],
            suggestedMood: .blue
        )
    ]

    static func collection(id: UUID) -> VisualCollection? {
        catalog.first { $0.id == id }
    }
}
