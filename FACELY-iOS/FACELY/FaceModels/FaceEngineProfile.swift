import Foundation

enum FaceEngineProfile: String, CaseIterable, Identifiable, Sendable {
    case faceNet = "current"
    case arcFace = "experimental"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .faceNet: return "FaceNet actual"
        case .arcFace: return "UniFace · ArcFace"
        }
    }

    var databaseFilename: String {
        switch self {
        case .faceNet: return "facely.db"
        case .arcFace: return "facely_arcface.db"
        }
    }

    var expectedEmbeddingDimensions: Int {
        switch self {
        case .faceNet: return 128
        case .arcFace: return 512
        }
    }
}
