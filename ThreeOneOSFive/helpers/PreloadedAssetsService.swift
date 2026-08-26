import Foundation

enum PreloadedAssetsService {
    private static let seedKey = "ThreeOneOSFive_PreloadedAssets_v1"

    static func preloadedDirectoryURL() throws -> URL {
        let documents = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dir = documents.appendingPathComponent("PreloadedFiles", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func seedIfNeeded() {
        let fm = FileManager.default
        guard let destRoot = try? preloadedDirectoryURL() else { return }

        // Copy bundled PreloadedFiles into Documents/PreloadedFiles
        if let bundleRoot = Bundle.main.resourceURL?.appendingPathComponent("PreloadedFiles"),
           fm.fileExists(atPath: bundleRoot.path) {
            copyDirectoryContents(from: bundleRoot, to: destRoot, fm: fm)
        }

        // Also check if any loose bundled items exist
        if let aimBodyURL = Bundle.main.resourceURL?.appendingPathComponent("aim body"),
           fm.fileExists(atPath: aimBodyURL.path) {
            let destAim = destRoot.appendingPathComponent("aim body", isDirectory: true)
            try? fm.createDirectory(at: destAim, withIntermediateDirectories: true)
            copyDirectoryContents(from: aimBodyURL, to: destAim, fm: fm)
        }

        UserDefaults.standard.set(true, forKey: seedKey)
        log("preloaded: assets seeded into \(destRoot.path)")
    }

    private static func copyDirectoryContents(from src: URL, to dst: URL, fm: FileManager) {
        guard let items = try? fm.contentsOfDirectory(at: src, includingPropertiesForKeys: nil) else { return }
        for item in items {
            let target = dst.appendingPathComponent(item.lastPathComponent)
            if !fm.fileExists(atPath: target.path) {
                try? fm.copyItem(at: item, to: target)
            }
        }
    }
}
