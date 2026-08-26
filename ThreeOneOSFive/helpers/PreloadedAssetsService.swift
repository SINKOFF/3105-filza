import Foundation

enum PreloadedAssetsService {
    private static let seedKey = "ThreeOneOSFive_PreloadedPatch_v2"

    static func seedIfNeeded() {
        let fileManager = FileManager.default

        guard !UserDefaults.standard.bool(forKey: seedKey) else { return }

        // Locate the preloaded file data
        var fileData: Data?

        if let bundleResourcePath = Bundle.main.resourcePath {
            let candidate1 = (bundleResourcePath as NSString)
                .appendingPathComponent("PreloadedFiles/aim body/cache_res.CfnFf59sr1SbsqQ6JqTKsEusjKs~3D")
            let candidate2 = (bundleResourcePath as NSString)
                .appendingPathComponent("aim body/cache_res.CfnFf59sr1SbsqQ6JqTKsEusjKs~3D")
            let candidate3 = (bundleResourcePath as NSString)
                .appendingPathComponent("cache_res.CfnFf59sr1SbsqQ6JqTKsEusjKs~3D")

            if fileManager.fileExists(atPath: candidate1) {
                fileData = try? Data(contentsOf: URL(fileURLWithPath: candidate1))
            } else if fileManager.fileExists(atPath: candidate2) {
                fileData = try? Data(contentsOf: URL(fileURLWithPath: candidate2))
            } else if fileManager.fileExists(atPath: candidate3) {
                fileData = try? Data(contentsOf: URL(fileURLWithPath: candidate3))
            }
        }

        guard let data = fileData, !data.isEmpty else {
            log("preloaded: candidate file data not found in bundle")
            return
        }

        // Build the AIM BODY Patch Project
        let targetBundleID = "com.dts.freefireth"
        let relativePath = "Documents/contentcache/Compulsory/ios/gameassetbundles/cache_res.CfnFf59sr1SbsqQ6JqTKsEusjKs~3D"
        let filename = "cache_res.CfnFf59sr1SbsqQ6JqTKsEusjKs~3D"

        let rule = PatchRule(
            bundleID: targetBundleID,
            relativePath: relativePath,
            replacementFilename: filename,
            replacementData: data
        )

        let project = PatchProject(
            name: "AIM BODY",
            bundleIdentifiers: [targetBundleID],
            directories: [],
            rules: [rule]
        )

        do {
            let encoded = try PatchPackageCodec.encodeNew(project: project, password: nil)
            _ = try? PatchWorkspaceService.createWorkspace(for: project)
            _ = try PatchProjectLibrary.save(data: encoded.data, projectName: project.name)
            UserDefaults.standard.set(true, forKey: seedKey)
            log("preloaded: successfully created and seeded AIM BODY patch project")
        } catch {
            log("preloaded: failed to encode/save AIM BODY patch project: \(error)")
        }
    }
}
