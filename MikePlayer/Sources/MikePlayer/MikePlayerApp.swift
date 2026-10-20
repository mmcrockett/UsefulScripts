import AppKit
import MikePlayerCore
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

@main
struct MikePlayerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    private let player = Player(settings: Settings(arguments: Array(CommandLine.arguments.dropFirst())))

    var body: some Scene {
        Window("Mike Player", id: "main") {
            ConsoleView(player: player)
                .frame(minWidth: 600, minHeight: 220)
        }
        .defaultSize(width: 650, height: 250)
    }
}
