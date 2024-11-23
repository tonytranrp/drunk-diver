//
//  YouTubeManager.swift
//  driver simu
//
//  Created by Tony on 22/11/2024.
//
import Foundation
import AVFoundation

class YoutubeManager {
    static let shared = YoutubeManager()
    private var tempDirectory: URL
    private var downloadedTracks: [TrackInfo] = []
    
    // Updated paths to check for yt-dlp
    private let possibleYtDlpPaths = [
        "/usr/local/bin/yt-dlp",              // Homebrew default
        "/usr/local/Cellar/yt-dlp/2024.11.18/bin/yt-dlp",  // Your specific installation
        "/opt/homebrew/bin/yt-dlp",
        "/usr/bin/yt-dlp"
    ]
    
    struct TrackInfo {
        let title: String
        let url: URL
        let thumbnailURL: String?
        var isPlaying: Bool = false
    }
    
    private init() {
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("youtube_tracks")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        createSymlink()  // Create symlink to yt-dlp
    }
    
    private func createSymlink() {
        // Try to create a symlink in /usr/local/bin if it doesn't exist
        let targetPath = "/usr/local/Cellar/yt-dlp/2024.11.18/bin/yt-dlp"
        let symlinkPath = "/usr/local/bin/yt-dlp"
        
        if !FileManager.default.fileExists(atPath: symlinkPath) {
            try? FileManager.default.createSymbolicLink(
                atPath: symlinkPath,
                withDestinationPath: targetPath
            )
        }
    }
    
    private func findYtDlpPath() -> String? {
        for path in possibleYtDlpPaths {
            if FileManager.default.fileExists(atPath: path) {
                print("Found yt-dlp at: \(path)")  // Debug print
                return path
            }
        }
        return nil
    }
    
    func downloadVideo(from youtubeURL: String, completion: @escaping (Result<TrackInfo, Error>) -> Void) {
        guard let ytDlpPath = findYtDlpPath() else {
            print("yt-dlp not found in any expected location")  // Debug print
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: """
                yt-dlp not found. Please try these steps:
                1. Open Terminal
                2. Run these commands:
                   brew link yt-dlp
                   brew link --overwrite yt-dlp
                3. Restart the app
                
                If that doesn't work, try:
                ln -s /usr/local/Cellar/yt-dlp/2024.11.18/bin/yt-dlp /usr/local/bin/yt-dlp
                """
            ])))
            return
        }
        
        // Create unique output path
        let fileName = UUID().uuidString
        let outputPath = tempDirectory.appendingPathComponent(fileName).path
        
        print("Using yt-dlp at: \(ytDlpPath)")  // Debug print
        print("Saving to: \(outputPath)")       // Debug print
        
        // Get title
        let titleProcess = Process()
        titleProcess.executableURL = URL(fileURLWithPath: ytDlpPath)
        titleProcess.arguments = ["--get-title", "--no-warnings", youtubeURL]
        
        let titlePipe = Pipe()
        titleProcess.standardOutput = titlePipe
        let errorPipe = Pipe()
        titleProcess.standardError = errorPipe
        
        do {
            try titleProcess.run()
            titleProcess.waitUntilExit()
            
            if titleProcess.terminationStatus != 0 {
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                print("Error getting title: \(errorMessage)")  // Debug print
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            }
            
            let titleData = titlePipe.fileHandleForReading.readDataToEndOfFile()
            let title = String(data: titleData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown Title"
            
            // Download process
            let downloadProcess = Process()
            downloadProcess.executableURL = URL(fileURLWithPath: ytDlpPath)
            downloadProcess.arguments = [
                "-x",                    // Extract audio
                "--audio-format", "mp3", // Convert to mp3
                "--no-warnings",         // Reduce output
                "-o", "\(outputPath).%(ext)s",  // Output path
                youtubeURL              // URL to download
            ]
            
            let downloadErrorPipe = Pipe()
            downloadProcess.standardError = downloadErrorPipe
            
            try downloadProcess.run()
            downloadProcess.waitUntilExit()
            
            if downloadProcess.terminationStatus == 0 {
                let finalPath = URL(fileURLWithPath: "\(outputPath).mp3")
                let trackInfo = TrackInfo(
                    title: title,
                    url: finalPath,
                    thumbnailURL: nil
                )
                downloadedTracks.append(trackInfo)
                completion(.success(trackInfo))
            } else {
                let errorData = downloadErrorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorMessage = String(data: errorData, encoding: .utf8) ?? "Download failed"
                print("Download error: \(errorMessage)")  // Debug print
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
            }
        } catch {
            print("Process error: \(error.localizedDescription)")  // Debug print
            completion(.failure(error))
        }
    }
    
    func getTracks() -> [TrackInfo] {
        return downloadedTracks
    }
    
    func cleanup() {
        try? FileManager.default.removeItem(at: tempDirectory)
    }
    
    deinit {
        cleanup()
    }
}
