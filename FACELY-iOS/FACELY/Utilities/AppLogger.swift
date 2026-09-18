import OSLog

enum AppLogger {
    static let database = Logger(subsystem: "ar.com.rostrolocal.facely", category: "database")
    static let app = Logger(subsystem: "ar.com.rostrolocal.facely", category: "app")
}
