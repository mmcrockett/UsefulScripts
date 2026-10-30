# MikePlayer

Native macOS (SwiftUI) port of the `mikeplayer` Ruby console player. Same look, same keys
(`c` pause/play, `v` next, `z` previous, `j` jump to a track by name (type to filter, Enter or 1-9 to pick, Esc cancels), `t` set timer then digits, `q` quit), same
`~/.mikeplayer/*.mpl` playlists and flags. Adds a Dock icon.

Needs only the Command Line Tools (no Xcode).

    ./build-app.sh            # builds build/MikePlayer.app
    ./build-app.sh --install  # also copies it to ~/Applications
    swift run MikePlayerChecks  # logic checks (XCTest/Swift Testing need full Xcode)

Launch with flags:

    open -a MikePlayer --args --volume 0.5 --directory ~/DreamObjects/b137124-music/ [-s] [-r N] [-p name] [-t minutes] [search...]

Volume and directory are remembered, so launching from the Dock or Spotlight reuses them.
`mikeplayer-app` in `LinuxSetup/bash.functions.sh` wraps the above.
