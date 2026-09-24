import Foundation

enum CopyPastePatchService {
    private static var fileManager: FileManager { .default }

    private static var backupBaseURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let url = appSupport.appendingPathComponent("CopyPasteBackups", isDirectory: true)
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private static func projectBackupURL(bundleID: String, projectName: String) -> URL {
        let safeName = projectName.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? projectName
        let url = backupBaseURL.appendingPathComponent(bundleID, isDirectory: true).appendingPathComponent(safeName, isDirectory: true)
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Applies a patch project using Filza-style direct copy/paste with a clean original backup.
    static func apply(project: PatchProject, targetBundleID: String) throws -> PatchTransactionReceipt {
        guard let containerPath = ContainerStore.resolveAppContainerPath(bundleID: targetBundleID),
              ContainerStore.isApplicationContainerPath(containerPath) else {
            throw PatchPackageError.targetAppUnavailable(targetBundleID)
        }

        let containerURL = URL(fileURLWithPath: containerPath, isDirectory: true)
        let backupDir = projectBackupURL(bundleID: targetBundleID, projectName: project.name)

        log("copypaste: applying [\(project.name)] to container \(containerPath)")

        for rule in project.rules {
            let targetURL = containerURL.appendingPathComponent(rule.relativePath)
            let parentDir = targetURL.deletingLastPathComponent()

            // 1. Ensure destination directory exists
            if !fileManager.fileExists(atPath: parentDir.path) {
                try fileManager.createDirectory(at: parentDir, withIntermediateDirectories: true)
            }

            // 2. Clean Backup of original file (only if original exists and hasn't been backed up yet)
            let backupFile = backupDir.appendingPathComponent((rule.relativePath as NSString).lastPathComponent + ".clean")
            if fileManager.fileExists(atPath: targetURL.path) {
                if !fileManager.fileExists(atPath: backupFile.path) {
                    try? fileManager.copyItem(at: targetURL, to: backupFile)
                    log("copypaste: backed up original -> \(backupFile.lastPathComponent)")
                }
            }

            // 3. Paste & Replace modded data (Filza-style)
            if fileManager.fileExists(atPath: targetURL.path) {
                try? fileManager.removeItem(at: targetURL)
            }
            try rule.replacementData.write(to: targetURL, options: .atomic)
            log("copypaste: pasted & replaced -> \(rule.relativePath)")
        }

        return PatchTransactionReceipt(
            id: UUID(),
            projectID: project.id,
            journalURL: backupDir
        )
    }

    /// Restores original clean files for a given patch.
    static func restore(project: PatchProject, targetBundleID: String) {
        guard let containerPath = ContainerStore.resolveAppContainerPath(bundleID: targetBundleID),
              ContainerStore.isApplicationContainerPath(containerPath) else {
            return
        }

        let containerURL = URL(fileURLWithPath: containerPath, isDirectory: true)
        let backupDir = projectBackupURL(bundleID: targetBundleID, projectName: project.name)

        for rule in project.rules {
            let targetURL = containerURL.appendingPathComponent(rule.relativePath)
            let backupFile = backupDir.appendingPathComponent((rule.relativePath as NSString).lastPathComponent + ".clean")

            if fileManager.fileExists(atPath: backupFile.path) {
                // Restore original file
                if fileManager.fileExists(atPath: targetURL.path) {
                    try? fileManager.removeItem(at: targetURL)
                }
                try? fileManager.copyItem(at: backupFile, to: targetURL)
                try? fileManager.removeItem(at: backupFile)
                log("copypaste: restored clean original -> \(rule.relativePath)")
            } else {
                // If there was no original file, delete the mod file
                try? fileManager.removeItem(at: targetURL)
                log("copypaste: removed modded file (no original) -> \(rule.relativePath)")
            }
        }

        try? fileManager.removeItem(at: backupDir)
    }
}
