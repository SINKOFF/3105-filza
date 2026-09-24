import Foundation
import Darwin

enum CopyPastePatchService {
    private static var fileManager: FileManager { .default }

    private static var backupBaseURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let url = appSupport.appendingPathComponent("CopyPasteBackups", isDirectory: true)
        ensureDirectory(at: url.path)
        return url
    }

    private static func projectBackupURL(bundleID: String, projectName: String) -> URL {
        let safeName = projectName.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? projectName
        let url = backupBaseURL.appendingPathComponent(bundleID, isDirectory: true).appendingPathComponent(safeName, isDirectory: true)
        ensureDirectory(at: url.path)
        return url
    }

    private static func ensureDirectory(at path: String) {
        if !fileManager.fileExists(atPath: path) {
            try? fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
        chmod(path, 0o777)
    }

    private static func writeDirectly(data: Data, to path: String) throws {
        let parent = (path as NSString).deletingLastPathComponent
        ensureDirectory(at: parent)

        unlink(path)
        let fd = open(path, O_WRONLY | O_CREAT | O_TRUNC, 0o666)
        if fd >= 0 {
            data.withUnsafeBytes { ptr in
                guard let base = ptr.baseAddress else { return }
                var writtenTotal = 0
                while writtenTotal < data.count {
                    let w = write(fd, base.advanced(by: writtenTotal), data.count - writtenTotal)
                    if w <= 0 { break }
                    writtenTotal += w
                }
            }
            close(fd)
            chmod(path, 0o666)
        } else {
            // Non-atomic fallback
            try data.write(to: URL(fileURLWithPath: path), options: [])
        }
    }

    private static func copyDirectly(from src: String, to dst: String) {
        let dstParent = (dst as NSString).deletingLastPathComponent
        ensureDirectory(at: dstParent)
        unlink(dst)
        if let data = try? Data(contentsOf: URL(fileURLWithPath: src)) {
            try? writeDirectly(data: data, to: dst)
        } else {
            try? fileManager.copyItem(atPath: src, toPath: dst)
        }
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
            let targetPath = targetURL.path
            let backupFile = backupDir.appendingPathComponent((rule.relativePath as NSString).lastPathComponent + ".clean")

            // 1. Clean Backup of original file (only if original exists and hasn't been backed up yet)
            if fileManager.fileExists(atPath: targetPath) {
                if !fileManager.fileExists(atPath: backupFile.path) {
                    copyDirectly(from: targetPath, to: backupFile.path)
                    log("copypaste: backed up original -> \(backupFile.lastPathComponent)")
                }
            }

            // 2. Paste & Replace modded data (Filza-style low-level write)
            try writeDirectly(data: rule.replacementData, to: targetPath)
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
            let targetPath = targetURL.path
            let backupFile = backupDir.appendingPathComponent((rule.relativePath as NSString).lastPathComponent + ".clean")

            if fileManager.fileExists(atPath: backupFile.path) {
                // Restore original file
                copyDirectly(from: backupFile.path, to: targetPath)
                unlink(backupFile.path)
                log("copypaste: restored clean original -> \(rule.relativePath)")
            } else {
                // If there was no original file, delete the mod file
                unlink(targetPath)
                log("copypaste: removed modded file (no original) -> \(rule.relativePath)")
            }
        }

        try? fileManager.removeItem(at: backupDir)
    }
}
