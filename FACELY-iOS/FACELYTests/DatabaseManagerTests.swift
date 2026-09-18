import XCTest
@testable import FACELY

final class DatabaseManagerTests: XCTestCase {
    func testCreatesVersionOneSchemaWithoutMixingEngineDatabases() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let faceNetURL = directory.appendingPathComponent("facely.db")
        let arcFaceURL = directory.appendingPathComponent("facely_arcface.db")

        let faceNet = try DatabaseManager(profile: .faceNet, url: faceNetURL)
        let arcFace = try DatabaseManager(profile: .arcFace, url: arcFaceURL)

        XCTAssertEqual(try await faceNet.initialize(), 1)
        XCTAssertEqual(try await arcFace.initialize(), 1)
        XCTAssertNotEqual(faceNetURL, arcFaceURL)

        for table in ["photos", "faces", "person_clusters"] {
            XCTAssertTrue(try await faceNet.hasTable(table))
            XCTAssertTrue(try await arcFace.hasTable(table))
        }
    }

    func testEngineProfilesKeepAndroidCompatibleDimensionsConceptuallySeparated() {
        XCTAssertEqual(FaceEngineProfile.faceNet.expectedEmbeddingDimensions, 128)
        XCTAssertEqual(FaceEngineProfile.arcFace.expectedEmbeddingDimensions, 512)
        XCTAssertNotEqual(FaceEngineProfile.faceNet.databaseFilename, FaceEngineProfile.arcFace.databaseFilename)
    }
}
