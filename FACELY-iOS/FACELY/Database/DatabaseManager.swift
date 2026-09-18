import Foundation
import SQLite3

actor DatabaseManager {
    private var db: OpaquePointer?
    private let profile: FaceEngineProfile
    private let url: URL

    init(profile: FaceEngineProfile, url: URL? = nil) throws {
        self.profile = profile
        if let url {
            self.url = url
        } else {
            self.url = try Self.defaultDatabaseURL(filename: profile.databaseFilename)
        }
    }

    deinit {
        if let db {
            sqlite3_close(db)
        }
    }

    @discardableResult
    func initialize() throws -> Int {
        try openIfNeeded()
        try execute("PRAGMA foreign_keys = ON")
        try migrateIfNeeded()
        return try schemaVersion()
    }

    func schemaVersion() throws -> Int {
        try openIfNeeded()
        return Int(try scalarInt("PRAGMA user_version"))
    }

    func hasTable(_ name: String) throws -> Bool {
        try openIfNeeded()
        let sql = "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name=?"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw lastError(statement: sql)
        }
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_text(statement, 1, name, -1, SQLITE_TRANSIENT)
        guard sqlite3_step(statement) == SQLITE_ROW else {
            throw lastError(statement: sql)
        }
        return sqlite3_column_int64(statement, 0) > 0
    }

    private func migrateIfNeeded() throws {
        let version = try schemaVersion()
        guard version <= Int(DatabaseSchema.currentVersion) else {
            throw SQLiteError(
                code: SQLITE_MISMATCH,
                message: "La base tiene una versión más nueva (\(version)) que esta app (\(DatabaseSchema.currentVersion)).",
                statement: nil
            )
        }

        if version < 1 {
            try transaction {
                for sql in DatabaseSchema.version1Statements {
                    try execute(sql)
                }
                try execute("PRAGMA user_version = 1")
            }
        }
    }

    private func transaction(_ body: () throws -> Void) throws {
        try execute("BEGIN IMMEDIATE TRANSACTION")
        do {
            try body()
            try execute("COMMIT")
        } catch {
            try? execute("ROLLBACK")
            throw error
        }
    }

    private func openIfNeeded() throws {
        guard db == nil else { return }

        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        var handle: OpaquePointer?
        let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
        let result = sqlite3_open_v2(url.path, &handle, flags, nil)
        guard result == SQLITE_OK, let handle else {
            let message = handle.map { String(cString: sqlite3_errmsg($0)) } ?? "No se pudo abrir SQLite"
            if let handle { sqlite3_close(handle) }
            throw SQLiteError(code: result, message: message, statement: nil)
        }
        db = handle
        sqlite3_busy_timeout(handle, 5_000)
    }

    private func execute(_ sql: String) throws {
        try openIfNeeded()
        var errorMessage: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(db, sql, nil, nil, &errorMessage)
        guard result == SQLITE_OK else {
            let message = errorMessage.map { String(cString: $0) } ?? lastError(statement: sql).message
            sqlite3_free(errorMessage)
            throw SQLiteError(code: result, message: message, statement: sql)
        }
    }

    private func scalarInt(_ sql: String) throws -> Int64 {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw lastError(statement: sql)
        }
        defer { sqlite3_finalize(statement) }
        guard sqlite3_step(statement) == SQLITE_ROW else {
            throw lastError(statement: sql)
        }
        return sqlite3_column_int64(statement, 0)
    }

    private func lastError(statement: String?) -> SQLiteError {
        let code = db.map(sqlite3_errcode) ?? SQLITE_ERROR
        let message = db.map { String(cString: sqlite3_errmsg($0)) } ?? "SQLite error"
        return SQLiteError(code: code, message: message, statement: statement)
    }

    private static func defaultDatabaseURL(filename: String) throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return base.appendingPathComponent("FACELY", isDirectory: true)
            .appendingPathComponent(filename, isDirectory: false)
    }
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
