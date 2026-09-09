import Foundation

enum ListeningMood: String, CaseIterable, Codable, Hashable, Identifiable {
    case night
    case hype
    case chill
    case focus
    case live
    case blue

    var id: String { rawValue }

    var title: String {
        switch self {
        case .night: return "Night"
        case .hype: return "Hype"
        case .chill: return "Chill"
        case .focus: return "Focus"
        case .live: return "Live"
        case .blue: return "Blue"
        }
    }

    var symbol: String {
        switch self {
        case .night: return "moon.fill"
        case .hype: return "bolt.fill"
        case .chill: return "leaf.fill"
        case .focus: return "scope"
        case .live: return "dot.radiowaves.left.and.right"
        case .blue: return "cloud.rain.fill"
        }
    }
}

struct ListenLog: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var momentId: UUID
    var playedAt: Date

    init(id: UUID = UUID(), momentId: UUID, playedAt: Date = Date()) {
        self.id = id
        self.momentId = momentId
        self.playedAt = playedAt
    }
}
