import Foundation

enum DatabaseSchema {
    static let currentVersion: Int32 = 1

    static let version1Statements: [String] = [
        """
        CREATE TABLE IF NOT EXISTS photos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            asset_identifier TEXT NOT NULL UNIQUE,
            display_name TEXT,
            modification_date REAL,
            analyzed_at REAL NOT NULL,
            face_count INTEGER NOT NULL DEFAULT 0,
            embedding_version TEXT
        )
        """,
        """
        CREATE TABLE IF NOT EXISTS person_clusters (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            label TEXT,
            created_at REAL NOT NULL,
            discarded INTEGER NOT NULL DEFAULT 0 CHECK(discarded IN (0, 1))
        )
        """,
        """
        CREATE TABLE IF NOT EXISTS faces (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            photo_id INTEGER NOT NULL,
            left REAL NOT NULL,
            top REAL NOT NULL,
            right REAL NOT NULL,
            bottom REAL NOT NULL,
            embedding BLOB NOT NULL,
            cluster_id INTEGER,
            FOREIGN KEY(photo_id) REFERENCES photos(id) ON DELETE CASCADE,
            FOREIGN KEY(cluster_id) REFERENCES person_clusters(id) ON DELETE SET NULL
        )
        """,
        "CREATE INDEX IF NOT EXISTS idx_faces_photo_id ON faces(photo_id)",
        "CREATE INDEX IF NOT EXISTS idx_faces_cluster_id ON faces(cluster_id)",
        "CREATE UNIQUE INDEX IF NOT EXISTS idx_photos_asset_identifier ON photos(asset_identifier)"
    ]
}
