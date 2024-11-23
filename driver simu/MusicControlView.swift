//
//  MusicControlView.swift
//  driver simu
//
//  Created by Tony on 22/11/2024.
//
import AppKit

class MusicControlView: NSView {
    private var trackList: NSTableView!
    private var playButton: NSButton!
    private var stopButton: NSButton!
    private var tracks: [YoutubeManager.TrackInfo] = []
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.withAlphaComponent(0.8).cgColor
        layer?.cornerRadius = 10
        
        // Create table view
        let scrollView = NSScrollView(frame: NSRect(x: 10, y: 50, width: frame.width - 20, height: frame.height - 100))
        trackList = NSTableView()
        trackList.headerView = nil
        trackList.addTableColumn(NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Track")))
        trackList.delegate = self
        trackList.dataSource = self
        trackList.backgroundColor = .clear
        scrollView.documentView = trackList
        addSubview(scrollView)
        
        // Create buttons
        playButton = NSButton(frame: NSRect(x: 10, y: 10, width: 60, height: 30))
        playButton.title = "Play"
        playButton.bezelStyle = .rounded
        playButton.target = self
        playButton.action = #selector(togglePlayPause)
        addSubview(playButton)
        
        stopButton = NSButton(frame: NSRect(x: 80, y: 10, width: 60, height: 30))
        stopButton.title = "Stop"
        stopButton.bezelStyle = .rounded
        stopButton.target = self
        stopButton.action = #selector(stopMusic)
        addSubview(stopButton)
    }
    
    func updateTracks() {
        tracks = YoutubeManager.shared.getTracks()
        trackList.reloadData()
    }
    
    @objc private func togglePlayPause() {
        if MusicPlayer.shared.isPlaying() {
            MusicPlayer.shared.pause()
            playButton.title = "Play"
        } else {
            if let currentTrack = MusicPlayer.shared.getCurrentTrack() {
                MusicPlayer.shared.resume()
            } else if let firstTrack = tracks.first {
                MusicPlayer.shared.play(track: firstTrack)
            }
            playButton.title = "Pause"
        }
    }
    
    @objc private func stopMusic() {
        MusicPlayer.shared.stop()
        playButton.title = "Play"
    }
}

extension MusicControlView: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return tracks.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = NSTextField()
        cell.stringValue = tracks[row].title
        cell.isEditable = false
        cell.isBordered = false
        cell.backgroundColor = .clear
        cell.textColor = .white
        return cell
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        MusicPlayer.shared.play(track: tracks[row])
        playButton.title = "Pause"
        return true
    }
}
