//
//  MusicMenu.swift
//  driver simu
//
//  Created by Tony on 22/11/2024.
//
import AVFoundation

class MusicPlayer {
    static let shared = MusicPlayer()
    
    private var audioPlayer: AVAudioPlayer?
    private var currentTrack: YoutubeManager.TrackInfo?
    
    func play(track: YoutubeManager.TrackInfo) {
        do {
            audioPlayer?.stop()
            audioPlayer = try AVAudioPlayer(contentsOf: track.url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            currentTrack = track
        } catch {
            print("Error playing track: \(error)")
        }
    }
    
    func stop() {
        audioPlayer?.stop()
        currentTrack = nil
    }
    
    func pause() {
        audioPlayer?.pause()
    }
    
    func resume() {
        audioPlayer?.play()
    }
    
    func isPlaying() -> Bool {
        return audioPlayer?.isPlaying ?? false
    }
    
    func getCurrentTrack() -> YoutubeManager.TrackInfo? {
        return currentTrack
    }
}
