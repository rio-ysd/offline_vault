import Foundation
import Photos

struct MediaItem: Identifiable, Codable, Hashable {
    let id: UUID
    let createdAt: Date
    let kind: Kind
    let filename: String

    enum Kind: String, Codable {
        case photo
        case video

        var symbolName: String { self == .photo ? "photo" : "video" }
    }
}

final class MediaLibrary: ObservableObject {
    @Published private(set) var items: [MediaItem] = []
    private let directory: URL
    private let metadataURL: URL

    init() {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        directory = root.appendingPathComponent("OfflineVault", isDirectory: true)
        metadataURL = directory.appendingPathComponent("media.json")
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        load()
    }

    func add(data: Data, kind: MediaItem.Kind) throws {
        let item = MediaItem(id: UUID(), createdAt: .now, kind: kind, filename: "\(UUID().uuidString).\(kind == .photo ? "jpg" : "mov")")
        try data.write(to: directory.appendingPathComponent(item.filename), options: [.atomic, .completeFileProtection])
        items.insert(item, at: 0)
        save()
    }

    func url(for item: MediaItem) -> URL { directory.appendingPathComponent(item.filename) }

    func delete(_ item: MediaItem) {
        try? FileManager.default.removeItem(at: url(for: item))
        items.removeAll { $0.id == item.id }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: metadataURL), let decoded = try? JSONDecoder().decode([MediaItem].self, from: data) else { return }
        items = decoded.filter { FileManager.default.fileExists(atPath: url(for: $0).path) }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: metadataURL, options: [.atomic, .completeFileProtection])
    }
}
