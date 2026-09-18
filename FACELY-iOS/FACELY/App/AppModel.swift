import Foundation

@MainActor
final class AppModel: ObservableObject {
    enum BootstrapState: Equatable {
        case idle
        case loading
        case ready(faceNetSchema: Int, arcFaceSchema: Int)
        case failed(String)
    }

    @Published private(set) var bootstrapState: BootstrapState = .idle

    func bootstrap() async {
        guard bootstrapState == .idle else { return }
        bootstrapState = .loading

        do {
            let faceNet = try DatabaseManager(profile: .faceNet)
            let arcFace = try DatabaseManager(profile: .arcFace)
            let faceNetSchema = try await faceNet.initialize()
            let arcFaceSchema = try await arcFace.initialize()
            bootstrapState = .ready(faceNetSchema: faceNetSchema, arcFaceSchema: arcFaceSchema)
        } catch {
            bootstrapState = .failed(error.localizedDescription)
        }
    }
}
