import Foundation

struct PersistenceController {
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    private var rootDirectory: URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("IpaDownloadToolNative", isDirectory: true)
    }

    var downloadsDirectory: URL {
        rootDirectory.appendingPathComponent("Downloads", isDirectory: true)
    }

    private var stateURL: URL {
        rootDirectory.appendingPathComponent("State.json")
    }

    func prepareDirectories() throws {
        try fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true, attributes: nil)
        try fileManager.createDirectory(at: downloadsDirectory, withIntermediateDirectories: true, attributes: nil)
    }

    func loadSnapshot() -> AppSnapshot {
        do {
            try prepareDirectories()
            let data = try Data(contentsOf: stateURL)
            return try decoder.decode(AppSnapshot.self, from: data)
        } catch {
            return AppSnapshot(settings: .init(), ipaHistory: [], webHistory: [])
        }
    }

    func saveSnapshot(_ snapshot: AppSnapshot) {
        do {
            try prepareDirectories()
            let data = try encoder.encode(snapshot)
            try data.write(to: stateURL, options: .atomic)
        } catch {
            assertionFailure("Failed to save snapshot: \(error)")
        }
    }

    func exportPayload(snapshot: AppSnapshot) -> String? {
        let exportedHistory = snapshot.ipaHistory.map { record in
            ExportedIpaRecord(
                id: record.id,
                title: record.title,
                version: record.version,
                bundleIdentifier: record.bundleIdentifier,
                downloadURL: record.downloadURL,
                iconURL: record.iconURL,
                fromPageURL: record.fromPageURL,
                createdAt: record.createdAt
            )
        }

        let export = ExportBundle(ipaHistory: exportedHistory, webHistory: snapshot.webHistory)

        do {
            let data = try encoder.encode(export)
            return String(decoding: data, as: UTF8.self)
        } catch {
            return nil
        }
    }

    func importPayload(_ text: String) throws -> ImportBundle {
        guard let data = text.data(using: .utf8) else {
            throw ImportError.invalidEncoding
        }

        if let modern = try? decoder.decode(ExportBundle.self, from: data) {
            return ImportBundle(
                ipaHistory: modern.ipaHistory.map(\.record),
                webHistory: modern.webHistory
            )
        }

        if let legacy = try? decoder.decode(LegacyExportBundle.self, from: data) {
            return ImportBundle(
                ipaHistory: legacy.ipaHistory.map(\.record),
                webHistory: legacy.webHistory
            )
        }

        throw ImportError.invalidPayload
    }

    func deleteFileIfNeeded(at url: URL) {
        try? fileManager.removeItem(at: url)
    }

    func fileExists(at url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path)
    }

    func fileSize(at url: URL) -> Int64 {
        let attributes = try? fileManager.attributesOfItem(atPath: url.path)
        return attributes?[.size] as? Int64 ?? 0
    }
}

enum ImportError: LocalizedError {
    case invalidEncoding
    case invalidPayload

    var errorDescription: String? {
        switch self {
        case .invalidEncoding:
            L10n.string("import.error.invalidEncoding")
        case .invalidPayload:
            L10n.string("import.error.invalidPayload")
        }
    }
}

struct ImportBundle {
    var ipaHistory: [IpaRecord]
    var webHistory: [WebHistoryEntry]
}

private struct ExportBundle: Codable {
    var ipaHistory: [ExportedIpaRecord]
    var webHistory: [WebHistoryEntry]
}

private struct ExportedIpaRecord: Codable {
    var id: String
    var title: String
    var version: String?
    var bundleIdentifier: String?
    var downloadURL: String
    var iconURL: String?
    var fromPageURL: String?
    var createdAt: Date

    var record: IpaRecord {
        IpaRecord(
            id: id,
            title: title,
            version: version,
            bundleIdentifier: bundleIdentifier,
            downloadURL: downloadURL,
            iconURL: iconURL,
            fromPageURL: fromPageURL,
            createdAt: createdAt,
            localFileName: nil
        )
    }
}

private struct LegacyExportBundle: Codable {
    var ipaHistory: [LegacyIpaRecord]
    var webHistory: [WebHistoryEntry]
}

private struct LegacyIpaRecord: Codable {
    var sign: String?
    var title: String?
    var version: String?
    var bundleId: String?
    var downloadUrl: String?
    var iconUrl: String?
    var fromPageUrl: String?
    var time: String?

    var record: IpaRecord {
        let parsedDate = time.flatMap { DateFormatter.legacyImportTimestamp.date(from: $0) } ?? .now
        return IpaRecord(
            id: sign ?? UUID().uuidString,
            title: title ?? L10n.string("common.untitledApp"),
            version: version,
            bundleIdentifier: bundleId,
            downloadURL: downloadUrl ?? "",
            iconURL: iconUrl,
            fromPageURL: fromPageUrl,
            createdAt: parsedDate,
            localFileName: nil
        )
    }
}
