import Foundation

struct SQLiteError: LocalizedError, Equatable {
    let code: Int32
    let message: String
    let statement: String?

    var errorDescription: String? {
        if let statement {
            return "SQLite \(code): \(message) [\(statement)]"
        }
        return "SQLite \(code): \(message)"
    }
}
