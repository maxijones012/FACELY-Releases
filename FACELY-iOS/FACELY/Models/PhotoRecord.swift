import Foundation

struct PhotoRecord: Identifiable, Sendable, Equatable {
    let id: Int64
    let assetIdentifier: String
    let displayName: String?
    let modificationDate: Date?
    let analyzedAt: Date
    let faceCount: Int
    let embeddingVersion: String?
}
