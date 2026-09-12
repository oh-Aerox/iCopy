import Foundation

enum AppPaths {
    static var supportDirectory: URL {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return root.appendingPathComponent(AppIdentity.supportDirectoryName, isDirectory: true)
    }

    static var historyFile: URL {
        supportDirectory.appendingPathComponent(AppIdentity.historyFileName)
    }

    static var settingsFile: URL {
        supportDirectory.appendingPathComponent(AppIdentity.settingsFileName)
    }

    static var imagesDirectory: URL {
        supportDirectory.appendingPathComponent(AppIdentity.imagesDirectoryName, isDirectory: true)
    }

    static func prepare() throws {
        try FileManager.default.createDirectory(at: supportDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
    }

    static func imageURL(_ filename: String) -> URL {
        imagesDirectory.appendingPathComponent(filename)
    }
}
