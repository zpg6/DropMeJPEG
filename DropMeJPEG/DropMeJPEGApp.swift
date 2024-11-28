//
//  DropMeJPEGApp.swift
//  DropMeJPEG
//
//  Created by Zachary Grimaldi on 11/27/24.
//

import Cocoa
import SwiftUI
import AppKit

@main
struct DropMeJPEGApp: App {
    @StateObject private var folderMonitor: FolderMonitor = FolderMonitor()
    
    var body: some Scene {
        MenuBarExtra("DropMeJPEG", systemImage: "photo") {
            Text("DropMeJPEG").bold()
            Divider()
            
            Toggle(isOn: $folderMonitor.isEnabled) {
                Text(folderMonitor.isEnabled ? "Enabled" : "Disabled")
            }
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }.keyboardShortcut("q")
        }
    }
}


class FolderMonitor: ObservableObject {
    @Published var isEnabled: Bool = true {
        didSet {
            isEnabled ? startMonitoring() : stopMonitoring()
        }
    }
    @Published var shouldDeleteOriginalInputFile = false
    private var folderURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
    private var monitor: DispatchSourceFileSystemObject?
    private var fileDescriptor: CInt = -1
    private var knownFiles: Set<String> = []
    
    init() {
        self.startMonitoring()
    }

    private func startMonitoring() {
        guard monitor == nil else { return }

        fileDescriptor = open(folderURL.path, O_EVTONLY)
        guard fileDescriptor != -1 else {
            print("Failed to open folder \(folderURL.path)")
            return
        }
        monitor = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDescriptor, eventMask: .write, queue: DispatchQueue.global())
        monitor?.setEventHandler { [weak self] in
            self?.handleFolderChanges()
        }
        monitor?.setCancelHandler {
            close(self.fileDescriptor)
            self.fileDescriptor = -1
        }
        refreshKnownFiles()
        monitor?.resume()
        print("Monitoring started at: \(folderURL.path)")
    }
    
    private func stopMonitoring() {
        monitor?.cancel()
        monitor = nil
        print("Monitoring stopped")
    }
    
    /// Prevent re-processing files that were in the directory before monitoring started - we only want to process new files.
    private func refreshKnownFiles() {
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: folderURL.path) else { return }
        let heicFiles = files.filter { $0.uppercased().hasSuffix(".HEIC") }
        knownFiles = Set(heicFiles)
        print("Known files: \(knownFiles)")
    }
    
    /// There are some folder changes, this function will handle detecting new HEIC files and converting them to JPEG.
    private func handleFolderChanges() {
        guard let currentFiles = try? FileManager.default.contentsOfDirectory(atPath: folderURL.path) else { return }
        let currentSet = Set(currentFiles)
        
        // Detect newly added files
        let newFiles = currentSet.subtracting(knownFiles)
        knownFiles = currentSet
        
        // Process new HEIC files
        newFiles
            .filter { $0.uppercased().hasSuffix(".HEIC") }
            .map { folderURL.appendingPathComponent($0) }
            .forEach {
                
                convertHEICtoJPEG($0)
            }
    }
        
    /// Conversion from HEIC to JPEG uses the `sips` command line tool that is built-into macOS.
    private func convertHEICtoJPEG(_ fileURL: URL) {
        print("PROCESSING INPUT URL: \(fileURL)")
        let outputURL = fileURL.deletingPathExtension().appendingPathExtension("jpeg")
        
        do {
            // Set up and execute the `sips` command
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
            process.arguments = [
                "--setProperty", "format", "jpeg",
                "--out", outputURL.path,
                fileURL.path
            ]
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe
            try process.run()
            process.waitUntilExit()
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            if !outputData.isEmpty { print("convertHEICtoJPEG Output: \(String(data: outputData, encoding: .utf8) ?? "")") }
            if !errorData.isEmpty { print("convertHEICtoJPEG Error: \(String(data: errorData, encoding: .utf8) ?? "")") }
            
            if process.terminationStatus == 0 {
                try FileManager.default.removeItem(at: fileURL)
            } else {
                print("SIPS command failed (status: \(process.terminationStatus))")
            }
        } catch {
            print("convertHEICtoJPEG failed: \(error)")
        }
    }
}
