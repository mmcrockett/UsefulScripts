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
        }

        if let error = player.error {
            line(Text(error).foregroundStyle(Self.red))
        }
    }

    private var blank: some View { Text(" ") }

    private func line(_ text: Text) -> some View { text }

    private func handle(_ press: KeyPress) -> KeyPress.Result {
        guard !press.modifiers.contains(.command) else { return .ignored }

        switch press.characters {
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
