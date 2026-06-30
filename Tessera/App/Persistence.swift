import Foundation

/// A tiny Codable-to-disk store. Files live in Application Support so they persist
/// across launches but stay out of iCloud/document backups by default. All access
/// is synchronous and local — there is no network layer anywhere in Tessera.
struct CodableFileStore {
    private let directory: URL
    private let fileManager = FileManager.default

    init(folderName: String = "TesseraData") {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        self.directory = base.appendingPathComponent(folderName, isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    private func url(for name: String) -> URL {
        directory.appendingPathComponent("\(name).json", isDirectory: false)
    }

    func load<T: Decodable>(_ type: T.Type, from name: String) -> T? {
        let url = url(for: name)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    func save<T: Encodable>(_ value: T, to name: String) {
        let url = url(for: name)
        guard let data = try? JSONEncoder().encode(value) else { return }
        try? data.write(to: url, options: [.atomic])
    }

    func delete(_ name: String) {
        try? fileManager.removeItem(at: url(for: name))
    }
}
