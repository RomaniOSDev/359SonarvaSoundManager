import Foundation

struct AudioMemo: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var relatedTrackId: UUID
    var caption: String
    var date: Date

    init(
        id: UUID = UUID(),
        relatedTrackId: UUID,
        caption: String,
        date: Date = Date()
    ) {
        self.id = id
        self.relatedTrackId = relatedTrackId
        self.caption = caption
        self.date = date
    }
}
