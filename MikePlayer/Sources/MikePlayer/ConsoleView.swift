import AppKit
import MikePlayerCore
import SwiftUI

struct ConsoleView: View {
    let player: Player

    @FocusState private var focused: Bool

    private static let dim = Color(white: 0.55)
    private static let green = Color(red: 0.2, green: 0.8, blue: 0.2)
    private static let red = Color(red: 1.0, green: 0.3, blue: 0.3)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Mike Player v\(Display.version)").bold()
            if player.state == .loading {
                line(Text("Loading playlist...").foregroundStyle(Self.dim))
            } else {
                line(Text("Playlist \(player.playlist.info)").foregroundStyle(Self.dim))
            }
            blank
            content
            Spacer(minLength: 0)
        }
        .font(.system(size: 13, design: .monospaced))
        .foregroundStyle(.white)
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.black)
        .preferredColorScheme(.dark)
        .navigationTitle(player.windowTitle)
        .focusable()
        .focusEffectDisabled()
        .focused($focused)
        .onAppear { focused = true }
        .task { await player.start() }
        .onKeyPress(phases: .down) { press in handle(press) }
    }

    @ViewBuilder private var content: some View {
        if player.state == .loading {
            EmptyView()
        } else if player.playlist.size == 0 {
            line(Text("No songs in playlist."))
        } else if let song = player.song {
            let paused = player.isPaused
            let stateColor = paused ? Self.red : Self.green

            HStack(spacing: 0) {
                Text("Playing ")
                Text(player.position).foregroundStyle(Self.dim)
                Text(": ")
                Text(song.info).bold().foregroundStyle(.cyan)
            }
            HStack(spacing: 0) {
                Text(Display.progressBar(elapsed: player.elapsed, length: song.length)).foregroundStyle(stateColor)
                Text(" \(Display.duration(song.length, elapsed: player.elapsed)) ")
                if let remaining = player.minutesRemaining {
                    Text("(\(remaining)\u{2193}) ").foregroundStyle(.yellow)
                }
                Text(player.state == .finished ? "FINISHED" : paused ? "PAUSED" : "PLAYING")
                    .foregroundStyle(stateColor)
            }
            blank
            line(Text(Display.hint).foregroundStyle(Self.dim))

            if let query = player.jumpQuery {
                blank
                jumpView(query)
            }
        }

        if let error = player.error {
            line(Text(error).foregroundStyle(Self.red))
        }
    }

    private var blank: some View { Text(" ") }

    private func line(_ text: Text) -> some View { text }

    @ViewBuilder private func jumpView(_ query: String) -> some View {
        let hits = player.playlist.matches(query)

        Text("Jump: \(query)_").foregroundStyle(.yellow)

        ForEach(Array(hits.enumerated()), id: \.offset) { n, i in
            HStack(spacing: 0) {
                Text("[\(n + 1)] ").foregroundStyle(.yellow)
                Text(player.playlist.songs[i].info).foregroundStyle(.cyan)
                Text(" \(player.playlist.position(i))").foregroundStyle(Self.dim)
            }
        }

        if !query.isEmpty && hits.isEmpty {
            line(Text("No matches.").foregroundStyle(Self.dim))
        }
    }

    private func handleJump(_ press: KeyPress, query: String) -> KeyPress.Result {
        let hits = player.playlist.matches(query)

        switch press.key {
        case .escape:
            player.jumpQuery = nil
        case .return:
            if let first = hits.first { player.jump(to: first) }
            player.jumpQuery = nil
        case .delete:
            player.jumpQuery = String(query.dropLast())
        default:
            guard press.characters.count == 1, let char = press.characters.first, !char.isNewline else {
                return .ignored
            }

            if let digit = char.wholeNumberValue, char.isASCII {
                if digit >= 1, hits.indices.contains(digit - 1) {
                    player.jump(to: hits[digit - 1])
                    player.jumpQuery = nil
                }
            } else {
                player.jumpQuery = query + press.characters
            }
        }

        return .handled
    }

    private func handle(_ press: KeyPress) -> KeyPress.Result {
        guard !press.modifiers.contains(.command) else { return .ignored }

        if let query = player.jumpQuery { return handleJump(press, query: query) }

        switch press.characters {
        case "j" where player.state != .loading && player.playlist.size > 0: player.jumpQuery = ""
        case "c", " ": player.togglePause()
        case "v": player.next()
        case "z": player.previous()
        case "t": player.restartTimer()
        case "q": NSApp.terminate(nil)
        case let digit where Int(digit) != nil && digit.count == 1: player.timerDigit(Int(digit)!)
        default: return .ignored
        }

        return .handled
    }
}
