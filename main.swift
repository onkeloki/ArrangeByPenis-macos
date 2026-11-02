import SwiftUI
import AppKit

// MARK: - Finder-Anbindung per AppleScript

struct DesktopIcon {
    let index: Int      // Index in "items of desktop" (1-basiert)
    let name: String
    let x: Int
    let y: Int
}

enum FinderError: LocalizedError {
    case script(String)
    var errorDescription: String? {
        switch self { case .script(let m): return m }
    }
}

enum Finder {
    @discardableResult
    static func run(_ source: String) throws -> String {
        var err: NSDictionary?
        guard let script = NSAppleScript(source: source) else {
            throw FinderError.script("AppleScript konnte nicht erstellt werden.")
        }
        let result = script.executeAndReturnError(&err)
        if let err = err {
            let msg = err[NSAppleScript.errorMessage] as? String ?? "\(err)"
            throw FinderError.script(msg)
        }
        return result.stringValue ?? ""
    }

    static func esc(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
    }

    /// Liefert alle sichtbaren Desktop-Icons (ohne versteckte Dateien).
    static func icons() throws -> [DesktopIcon] {
        let out = try run("""
        set out to ""
        tell application "Finder"
          set n to count of items of desktop
          repeat with j from 1 to n
            set i to item j of desktop
            set nm to name of i
            set p to {-1, -1}
            try
              set p to desktop position of i
            end try
            set out to out & j & tab & nm & tab & (item 1 of p) & tab & (item 2 of p) & linefeed
          end repeat
        end tell
        return out
        """)
        return out.split(separator: "\n").compactMap { line in
            let f = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
            guard f.count == 4, let idx = Int(f[0]) else { return nil }
            if f[1].hasPrefix(".") { return nil }
            return DesktopIcon(index: idx, name: f[1], x: Int(f[2]) ?? -1, y: Int(f[3]) ?? -1)
        }
    }

    static func desktopSize() throws -> (w: Int, h: Int) {
        let out = try run("""
        tell application "Finder" to set b to bounds of window of desktop
        return ((item 3 of b) as text) & "," & ((item 4 of b) as text)
        """)
        let p = out.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        guard p.count == 2 else { return (1440, 900) }
        return (p[0], p[1])
    }

    /// Setzt Positionen per Index.
    static func move(_ moves: [(index: Int, x: Int, y: Int)]) throws {
        guard !moves.isEmpty else { return }
        let lines = moves.map {
            "try\n set desktop position of item \($0.index) of desktop to {\($0.x), \($0.y)}\nend try"
        }.joined(separator: "\n")
        try run("tell application \"Finder\"\n\(lines)\nend tell")
    }

    /// Setzt Positionen per Name (für Rückgängig – Indizes können sich ändern).
    static func moveByName(_ moves: [(name: String, x: Int, y: Int)]) throws {
        guard !moves.isEmpty else { return }
        let lines = moves.map { m in
            """
            repeat with j from 1 to (count of items of desktop)
              set i to item j of desktop
              if name of i is "\(esc(m.name))" then
                try
                  set desktop position of i to {\(m.x), \(m.y)}
                end try
              end if
            end repeat
            """
        }.joined(separator: "\n")
        try run("tell application \"Finder\"\n\(lines)\nend tell")
    }

    static func cleanUp() {
        _ = try? run("tell application \"Finder\" to clean up window of desktop by name")
    }
}

// MARK: - Die Form

enum Shape {
    /// Berechnet für n Icons die Zielpunkte, zentriert auf einer Fläche w×h.
    static func points(count n: Int, width w: Int, height h: Int) -> [(Int, Int)] {
        guard n > 0 else { return [] }
        let tip = min(3, n)
        var balls = 0
        if n >= 7 {
            balls = max(4, Int((Double(n) / 3.0).rounded()))
            if balls % 2 == 1 { balls -= 1 }
        }
        let shaft = n - tip - balls

        // Abstand so wählen, dass alles auf den Bildschirm passt
        // Bei vielen Icons wird der Schaft zweispurig, damit nichts überlappt
        var cols = 1
        var rows = Double(shaft) + 1.8 + (balls > 0 ? 2.0 : 0.0)
        var s = min(100.0, Double(h - 160) / max(rows, 1.0))
        if s < 85 && shaft > 4 {
            cols = 2
            rows = Double((shaft + 1) / 2) + 1.8 + (balls > 0 ? 2.0 : 0.0)
            s = min(100.0, Double(h - 160) / max(rows, 1.0))
        }
        let cx = Double(w) / 2.0
        var y = (Double(h) - rows * s) / 2.0 + s / 2.0

        var pts: [(Double, Double)] = []
        // Spitze
        pts.append((cx, y))
        if tip >= 2 { pts.append((cx - s, y + s * 0.8)) }
        if tip >= 3 { pts.append((cx + s, y + s * 0.8)) }
        y += s * (tip >= 2 ? 1.8 : 1.0)
        // Schaft
        if cols == 1 {
            for _ in 0..<max(shaft, 0) { pts.append((cx, y)); y += s }
        } else {
            var left = shaft
            while left > 0 {
                if left == 1 { pts.append((cx, y)) }
                else { pts.append((cx - s * 0.5, y)); pts.append((cx + s * 0.5, y)) }
                left -= 2; y += s
            }
        }
        // Kugeln
        if balls > 0 {
            let per = balls / 2
            let r = per <= 1 ? 0 : max(s * 0.6, (s / 2.0) / sin(Double.pi / Double(per)))
            let off = r + s * 0.9
            for side in [-1.0, 1.0] {
                let bx = cx + side * off
                let by = y + r * 0.3
                for k in 0..<per {
                    let a = Double.pi / 2 + 2 * Double.pi * Double(k) / Double(per) + side * 0.4
                    pts.append((bx + r * cos(a), by + r * sin(a)))
                }
            }
        }
        return pts.map { (Int($0.0.rounded()), Int($0.1.rounded())) }
    }
}

// MARK: - UI

@MainActor
final class Model: ObservableObject {
    @Published var status = "Bereit."
    @Published var busy = false
    private var backup: [DesktopIcon] = []

    private let backupURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ArrangeByPenis", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("backup.tsv")
    }()

    init() { loadBackup() }

    var canUndo: Bool { !backup.isEmpty }

    func arrange() {
        busy = true; status = "Ordne an …"
        defer { busy = false }
        do {
            let icons = try Finder.icons()
            guard !icons.isEmpty else { status = "Keine Icons auf dem Schreibtisch gefunden."; return }
            if backup.isEmpty { backup = icons; saveBackup() }
            let size = try Finder.desktopSize()
            let pts = Shape.points(count: icons.count, width: size.w, height: size.h)
            try Finder.move(zip(icons, pts).map { ($0.index, $1.0, $1.1) })
            status = "Fertig 🍆 – \(icons.count) Icons angeordnet."
        } catch {
            status = "Fehler: \(error.localizedDescription)"
        }
    }

    func undo() {
        busy = true; status = "Stelle wieder her …"
        defer { busy = false }
        Finder.cleanUp()
        do {
            let known = backup.filter { $0.x >= 0 && $0.y >= 0 }.map { ($0.name, $0.x, $0.y) }
            try Finder.moveByName(known)
            backup = []; saveBackup()
            status = "Wiederhergestellt."
        } catch {
            status = "Fehler: \(error.localizedDescription)"
        }
    }

    private func saveBackup() {
        let text = backup.map { "\($0.index)\t\($0.name)\t\($0.x)\t\($0.y)" }.joined(separator: "\n")
        if text.isEmpty { try? FileManager.default.removeItem(at: backupURL) }
        else { try? text.write(to: backupURL, atomically: true, encoding: .utf8) }
    }

    private func loadBackup() {
        guard let text = try? String(contentsOf: backupURL, encoding: .utf8) else { return }
        backup = text.split(separator: "\n").compactMap { line in
            let f = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
            guard f.count == 4, let i = Int(f[0]) else { return nil }
            return DesktopIcon(index: i, name: f[1], x: Int(f[2]) ?? -1, y: Int(f[3]) ?? -1)
        }
    }
}

struct ContentView: View {
    @StateObject private var model = Model()

    var body: some View {
        VStack(spacing: 16) {
            Text("🍆").font(.system(size: 64))
            Button(action: model.arrange) {
                Text("Arrange by Penis")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(model.busy)

            Button("Rückgängig", action: model.undo)
                .disabled(model.busy || !model.canUndo)

            Text(model.status)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(width: 320)
    }
}

@main
struct ArrangeByPenisApp: App {
    var body: some Scene {
        WindowGroup("Arrange by Penis") { ContentView() }
            .windowResizability(.contentSize)
    }
}
