import Foundation

struct PersonClusterRecord: Identifiable, Sendable, Equatable {
    let id: Int64
    let label: String?
    let createdAt: Date
    let discarded: Bool
}
