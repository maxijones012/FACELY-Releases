import Foundation

struct FaceRecord: Identifiable, Sendable, Equatable {
    let id: Int64
    let photoID: Int64
    let left: Double
    let top: Double
    let right: Double
    let bottom: Double
    let embedding: Data
    let clusterID: Int64?
}
