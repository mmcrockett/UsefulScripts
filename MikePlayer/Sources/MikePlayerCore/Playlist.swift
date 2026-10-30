import Foundation

public final class Playlist {
    public static let audioExtensions: Set<String> = ["mp3", "m4a", "aac", "wav", "aif", "aiff", "flac"]

    public private(set) var songs: [Song] = []
    public let path: String
    public private(set) var loadedCount = 0

    public init(path: String) {
        self.path = path
    }

    public var size: Int { songs.count }
    public var length: Double { songs.reduce(0) { $0 + $1.length } }

    public var name: String {
        ((path as NSString).lastPathComponent as NSString).deletingPathExtension
    }

    public var info: String {
        "\(name) loaded \(loadedCount) and added \(size - loadedCount) songs with length \(Display.duration(length))"
    }

    public static func load(path: String) async -> Playlist {
        let playlist = Playlist(path: path)

        if let data = FileManager.default.contents(atPath: path),
           let files = try? JSONDecoder().decode([String].self, from: data) {
            for file in files {
                await playlist.add(file: file)
            }
        }

        playlist.loadedCount = playlist.size

        return playlist
    }

    public func append(_ song: Song) {
        guard !songs.contains(where: { $0.filename == song.filename }) else { return }

        songs.append(song)
    }

    public func add(file: String) async {
        var isDirectory: ObjCBool = false

        guard FileManager.default.fileExists(atPath: file, isDirectory: &isDirectory), !isDirectory.boolValue,
              !songs.contains(where: { $0.filename == file }) else { return }

        append(await Song.load(file))
    }

    public func findSong(_ term: String, directory: String) async {
        var isDirectory: ObjCBool = false

        if FileManager.default.fileExists(atPath: term, isDirectory: &isDirectory), !isDirectory.boolValue {
            await add(file: term)
            return
        }

        for file in Self.audioFiles(in: directory)
        where (file as NSString).lastPathComponent.localizedCaseInsensitiveContains(term) {
            await add(file: file)
        }
    }

    public func addRandom(_ n: Int, directory: String) async {
        let existing = Set(songs.map(\.filename))

        for file in Self.audioFiles(in: directory).filter({ !existing.contains($0) }).shuffled().prefix(n) {
            await add(file: file)
        }
    }

    public func shuffle() {
        songs.shuffle()
    }

    public func save() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]

        try FileManager.default.createDirectory(
            atPath: (path as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
        try encoder.encode(songs.map(\.filename)).write(to: URL(fileURLWithPath: path))
    }

    public func matches(_ query: String, limit: Int = 9) -> [Int] {
        guard !query.isEmpty else { return [] }

        let hits = songs.indices.lazy.filter {
            self.songs[$0].info.localizedCaseInsensitiveContains(query)
                || (self.songs[$0].filename as NSString).lastPathComponent.localizedCaseInsensitiveContains(query)
        }

        return Array(hits.prefix(limit))
    }

    public func position(_ i: Int) -> String {
        let number = String(i + 1)
        let padding = String(repeating: " ", count: max(String(size).count - number.count, 0))

        return "(\(padding)\(number)/\(size))"
    }

    static func audioFiles(in directory: String) -> [String] {
        guard let walker = FileManager.default.enumerator(atPath: directory) else { return [] }

        return walker.compactMap { $0 as? String }
            .filter { audioExtensions.contains(($0 as NSString).pathExtension.lowercased()) }
            .map { (directory as NSString).appendingPathComponent($0) }
            .sorted()
    }
}
