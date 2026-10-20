import AVFoundation
import Foundation

public struct Song: Equatable {
    public let filename: String
    public let artist: String
    public let title: String
    public let length: Double

    public init(filename: String, artist: String = "", title: String = "", length: Double = 0) {
        self.filename = filename
        self.artist = artist
        self.title = title
        self.length = length
    }

    public var info: String {
        if artist.isEmpty && title.isEmpty {
            return ((filename as NSString).lastPathComponent as NSString).deletingPathExtension
        }

        return "\(artist.isEmpty ? "?????" : artist) - \(title.isEmpty ? "?????" : title)"
    }

    public static func load(_ filename: String) async -> Song {
        let asset = AVURLAsset(url: URL(fileURLWithPath: filename))
        let items = (try? await asset.load(.commonMetadata)) ?? []
        let artist = await string(items, .commonIdentifierArtist)
        let title = await string(items, .commonIdentifierTitle)
        let seconds = (try? await asset.load(.duration).seconds) ?? 0

        return Song(filename: filename, artist: artist, title: title, length: seconds.isFinite ? seconds : 0)
    }

    private static func string(_ items: [AVMetadataItem], _ id: AVMetadataIdentifier) async -> String {
        guard let item = AVMetadataItem.metadataItems(from: items, filteredByIdentifier: id).first else { return "" }

        return ((try? await item.load(.stringValue)) ?? nil) ?? ""
    }
}
