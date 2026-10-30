import Foundation
import MikePlayerCore

var failures = 0

func check<T: Equatable>(_ actual: T, _ expected: T, _ name: String) {
    if actual == expected {
        print("ok   \(name)")
    } else {
        failures += 1
        print("FAIL \(name): expected \(expected), got \(actual)")
    }
}

func tempDir() -> String {
    let dir = NSTemporaryDirectory() + "mikeplayer-\(UUID().uuidString)"
    try! FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
    return dir
}

func touch(_ path: String) {
    FileManager.default.createFile(atPath: path, contents: Data())
}

func defaults() -> UserDefaults {
    let suite = "mikeplayer-checks-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    return defaults
}

// Display
check(Display.duration(243), "04:03", "duration under an hour")
check(Display.duration(243, elapsed: 9), "00:09 [04:03]", "duration with elapsed")
check(Display.duration(17 * 3600 + 48 * 60 + 34), "17:48:34", "duration over an hour")
check(Display.progressBar(elapsed: 0, length: 100, width: 10), "[----------]", "bar empty")
check(Display.progressBar(elapsed: 50, length: 100, width: 10), "[#####-----]", "bar half")
check(Display.progressBar(elapsed: 500, length: 100, width: 10), "[##########]", "bar clamped")
check(Display.progressBar(elapsed: 5, length: 0, width: 4), "[----]", "bar zero length")

// Song
check(Song(filename: "/m/Cats.mp3").info, "Cats", "info falls back to basename")
check(Song(filename: "/m/a.mp3", artist: "Muse").info, "Muse - ?????", "info missing title")
check(Song(filename: "/m/a.mp3", title: "Starlight").info, "????? - Starlight", "info missing artist")
check(Song(filename: "/m/a.mp3", artist: "Muse", title: "Starlight").info, "Muse - Starlight", "info full")

// Playlist
let padded = Playlist(path: "/tmp/default.mpl")
for i in 1...12 { padded.append(Song(filename: "/m/\(i).mp3", length: 60)) }
padded.append(Song(filename: "/m/1.mp3"))
check(padded.size, 12, "playlist dedupes")
check(padded.position(0), "( 1/12)", "position padded")
check(padded.position(11), "(12/12)", "position full")
check(padded.info, "default loaded 0 and added 12 songs with length 12:00", "playlist info")

let dir = tempDir()
let a = dir + "/a.mp3", b = dir + "/b.mp3"
touch(a)
touch(b)
let path = dir + "/default.mpl"
try! #"["\#(a)", "\#(b)", "\#(dir)/missing.mp3"]"#.write(toFile: path, atomically: true, encoding: .utf8)
let loaded = await Playlist.load(path: path)
check(loaded.songs.map(\.filename), [a, b], "loads gem-format playlist, skips missing")
check(loaded.loadedCount, 2, "loaded count")
try! loaded.save()
let saved = try! JSONDecoder().decode([String].self, from: Data(contentsOf: URL(fileURLWithPath: path)))
check(saved, [a, b], "save round-trips")

let findDir = tempDir()
touch(findDir + "/Cats-Song.mp3")
touch(findDir + "/Dogs.mp3")
touch(findDir + "/cats.txt")
let found = Playlist(path: findDir + "/p.mpl")
await found.findSong("cats", directory: findDir)
check(found.songs.map(\.filename), [findDir + "/Cats-Song.mp3"], "findSong case-insensitive, audio only")

let jumpList = Playlist(path: "/tmp/jump.mpl")
jumpList.append(Song(filename: "/m/1.mp3", artist: "American Cat", title: "Against the World"))
jumpList.append(Song(filename: "/m/2.mp3", artist: "Dogs", title: "Bark"))
jumpList.append(Song(filename: "/m/3.mp3", artist: "The Beats", title: "Catman Rises"))
jumpList.append(Song(filename: "/m/Catamaran Sailing.mp3"))
check(jumpList.matches("cat"), [0, 2, 3], "matches case-insensitive in playlist order, filename fallback")
check(jumpList.matches("CATMAN"), [2], "matches uppercase query")
check(jumpList.matches("cat", limit: 2), [0, 2], "matches honors limit")
check(jumpList.matches(""), [], "empty query matches nothing")
check(jumpList.matches("zzz"), [], "no match")

// Settings
let parsed = Settings(
    arguments: ["-s", "--volume", "0.5", "-d", "/music", "-t", "30", "cats", "--fullscreen", "-psn_0_1"],
    home: "/home", defaults: defaults())
check(parsed.shuffle, true, "flag shuffle")
check(parsed.volume, 0.5, "flag volume")
check(parsed.musicDir, "/music", "flag directory")
check(parsed.minutes, 30, "flag time")
check(parsed.searchTerms, ["cats"], "search terms, unknown flags ignored")
check(parsed.playlistPath, "/home/.mikeplayer/default.mpl", "default playlist path")

let remembered = defaults()
_ = Settings(arguments: ["-v", "0.5", "-d", "/music"], home: "/home", defaults: remembered)
let again = Settings(arguments: [], home: "/home", defaults: remembered)
check(again.volume, 0.5, "remembers volume")
check(again.musicDir, "/music", "remembers directory")

let fallback = Settings(arguments: [], home: "/home", defaults: defaults())
check(fallback.volume, Settings.defaultVolume, "default volume")
check(fallback.musicDir, "/home/Music", "default directory")
check(Settings(arguments: ["-r", "20"], home: "/home", defaults: defaults()).playlistPath,
      "/home/.mikeplayer/random_n20.mpl", "random playlist name")
check(Settings(arguments: ["-p", "workout.mpl"], home: "/home", defaults: defaults()).playlistPath,
      "/home/.mikeplayer/workout.mpl", "named playlist")

// Player
let player = Player(settings: Settings(arguments: [], home: "/nonexistent", defaults: defaults()))
player.timerDigit(5)
check(player.minutes, 0, "digits ignored before timer starts")
player.restartTimer()
player.timerDigit(1)
player.timerDigit(5)
check(player.minutes, 15, "digits accumulate after timer starts")

print(failures == 0 ? "all checks passed" : "\(failures) check(s) failed")
exit(failures == 0 ? 0 : 1)
