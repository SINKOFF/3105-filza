import Foundation

enum PreloadedAssetsService {

    // Bump this key if you add/remove patches so existing installs re-seed.
    private static let seedKey = "ThreeOneOSFive_PreloadedPatch_v4"

    // All patches share the same bundle ID and destination path.
    private static let targetBundleID = "com.dts.freefireth"
    private static let relativePath  = "Documents/contentcache/Compulsory/ios/gameassetbundles/cache_res.CfnFf59sr1SbsqQ6JqTKsEusjKs~3D"
    private static let filename      = "cache_res.CfnFf59sr1SbsqQ6JqTKsEusjKs~3D"

    // (patchName, folderName-inside-PreloadedFiles)
    private static let patches: [(name: String, folder: String)] = [
        ("AIM BODY",      "aim body"),
        ("AIM BODY 100%", "aim body 100%"),
        ("AIM BODY 80%",  "aim body 80%"),
        ("AIM DRAG",      "aim drag"),
        ("AIM MGIC",      "aim mgic"),
        ("AIM NECK",      "aim neck"),
    ]

    static func seedIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: seedKey) else { return }

        var seededCount = 0
        for patch in patches {
            if seedPatch(name: patch.name, folder: patch.folder) {
                seededCount += 1
            }
        }

        if seededCount > 0 {
            UserDefaults.standard.set(true, forKey: seedKey)
            log("preloaded: seeded \(seededCount) patch(es)")
        }
    }

    @discardableResult
    private static func seedPatch(name: String, folder: String) -> Bool {
        guard let data = loadBundleFile(folder: folder) else {
            log("preloaded: [\(name)] file not found in bundle folder '\(folder)'")
            return false
        }

        // Skip if a package with this exact name already exists.
        let existingNames = PatchProjectLibrary.load().compactMap { $0.project?.name }
        guard !existingNames.contains(name) else {
            log("preloaded: [\(name)] already exists, skipping")
            return true
        }

        let rule = PatchRule(
            bundleID: targetBundleID,
            relativePath: relativePath,
            replacementFilename: filename,
            replacementData: data
        )

        let project = PatchProject(
            name: name,
            bundleIdentifiers: [targetBundleID],
            directories: [],
            rules: [rule]
        )

        do {
            let encoded = try PatchPackageCodec.encodeNew(project: project, password: nil)
            _ = try? PatchWorkspaceService.createWorkspace(for: project)
            _ = try PatchProjectLibrary.save(data: encoded.data, projectName: project.name)
            log("preloaded: [\(name)] seeded successfully")
            return true
        } catch {
            log("preloaded: [\(name)] failed to save — \(error)")
            return false
        }
    }

    private static func loadBundleFile(folder: String) -> Data? {
        guard let resourcePath = Bundle.main.resourcePath else { return nil }

        let paths: [String] = [
            // Nested under PreloadedFiles/
            ((resourcePath as NSString)
                .appendingPathComponent("PreloadedFiles")
                as NSString)
                .appendingPathComponent(folder)
                .appending("/\(filename)"),
            // Directly at resource root (fallback)
            (resourcePath as NSString)
                .appendingPathComponent(folder)
                .appending("/\(filename)"),
        ]

        for path in paths {
            if FileManager.default.fileExists(atPath: path),
               let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
               !data.isEmpty {
                return data
            }
        }
        return nil
    }
}
