import AVFoundation
import Foundation
import MediaPlayer
import Observation

@MainActor @Observable
public final class Player: NSObject, AVAudioPlayerDelegate {
    public enum State { case loading, playing, paused, finished }

    public static let restartThreshold = 10.0

    public let settings: Settings
    public private(set) var playlist: Playlist
    public private(set) var state = State.loading
    public private(set) var index = 0
    public private(set) var elapsed = 0.0
    public private(set) var clock = Date()
    public private(set) var minutes: Int
    public private(set) var timerStart: Date?
    public private(set) var error: String?

    @ObservationIgnored private var audio: AVAudioPlayer?
    @ObservationIgnored private var ticker: Timer?

    public init(settings: Settings) {
        self.settings = settings
        self.playlist = Playlist(path: settings.playlistPath)
        self.minutes = settings.minutes
        self.timerStart = settings.minutes > 0 ? Date() : nil

        super.init()
    }

    public var song: Song? {
        playlist.songs.indices.contains(index) ? playlist.songs[index] : nil
    }

    public var position: String { playlist.position(index) }
    public var isPaused: Bool { state == .paused }

    public var minutesRemaining: Int? {
        guard minutes > 0, let timerStart else { return nil }

        return minutes - Int(clock.timeIntervalSince(timerStart) / 60)
    }

    public var windowTitle: String {
        guard let song, state != .finished else { return "Mike Player" }

        return "\(isPaused ? "\u{23F8}" : "\u{25B6}") \(song.info) \(position)"
    }

    public func start() async {
        do {
            try settings.prepare()
        } catch {
            self.error = "\(error)"
        }

        let list = await Playlist.load(path: settings.playlistPath)

        for term in settings.searchTerms {
            await list.findSong(term, directory: settings.musicDir)
        }

        if settings.isRandom {
            await list.addRandom(settings.random, directory: settings.musicDir)
        }

        try? list.save()

        if settings.shuffle { list.shuffle() }

        playlist = list

        ticker = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }

        setUpRemoteCommands()
        play(at: 0)
    }

    public func togglePause() {
        guard let audio else { return }

        switch state {
        case .playing:
            audio.pause()
            state = .paused
        case .paused:
            audio.play()
            state = .playing
        default:
            return
        }

        publishNowPlaying()
    }

    public func next() {
        guard state == .playing || state == .paused else { return }

        play(at: index + 1)
    }

    public func previous() {
        guard state == .playing || state == .paused else { return }

        play(at: elapsed < Self.restartThreshold ? max(index - 1, 0) : index)
    }

    public func restartTimer() {
        timerStart = Date()
    }

    public func timerDigit(_ digit: Int) {
        guard timerStart != nil else { return }

        minutes = minutes == 0 ? digit : minutes * 10 + digit
    }

    nonisolated public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in self.play(at: self.index + 1) }
    }

    private func play(at newIndex: Int) {
        audio?.stop()
        audio = nil

        guard playlist.songs.indices.contains(newIndex) else {
            index = min(newIndex, max(playlist.size - 1, 0))
            elapsed = 0
            state = .finished
            publishNowPlaying()
            return
        }

        index = newIndex
        elapsed = 0

        do {
            let player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: playlist.songs[newIndex].filename))
            player.delegate = self
            player.volume = Float(min(max(settings.volume, 0), 1))
            player.play()
            audio = player
            state = .playing
            publishNowPlaying()
        } catch {
            self.error = "\(playlist.songs[newIndex].filename): \(error.localizedDescription)"
            play(at: newIndex + 1)
        }
    }

    private func tick() {
        clock = Date()

        if let audio, state == .playing { elapsed = audio.currentTime }

        if state == .playing, let remaining = minutesRemaining, remaining <= 0 {
            togglePause()
            timerStart = nil
            minutes = 0
        }
    }

    private func publishNowPlaying() {
        guard let song, state != .finished else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: song.title.isEmpty ? song.info : song.title,
            MPMediaItemPropertyArtist: song.artist,
            MPMediaItemPropertyPlaybackDuration: song.length,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsed,
            MPNowPlayingInfoPropertyPlaybackRate: state == .playing ? 1.0 : 0.0,
        ]
        MPNowPlayingInfoCenter.default().playbackState = state == .playing ? .playing : .paused
    }

    private func setUpRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        let actions: [(MPRemoteCommand, () -> Void)] = [
            (center.togglePlayPauseCommand, { self.togglePause() }),
            (center.playCommand, { if self.isPaused { self.togglePause() } }),
            (center.pauseCommand, { if self.state == .playing { self.togglePause() } }),
            (center.nextTrackCommand, { self.next() }),
            (center.previousTrackCommand, { self.previous() }),
        ]

        for (command, action) in actions {
            command.isEnabled = true
            command.addTarget { _ in
                Task { @MainActor in action() }
                return .success
            }
        }
    }
}
