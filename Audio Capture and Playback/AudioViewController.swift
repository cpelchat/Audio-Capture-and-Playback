//
//  AudioViewController.swift
//  Audio Capture and Playback
//
//  Created by Cassidy Pelchat on 11/6/19.
//  Copyright © 2019 Cassidy Pelchat. All rights reserved.
//


import UIKit
import AVKit

class AudioViewController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    @IBOutlet weak var recordBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var playBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var statusLabel: UILabel!
    
    var audioSession: AVAudioSession?
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    var fileManager: FileManager?
    var documentDirectoryURL: URL?
    var audioFileName = "audio.caf"
    var audioFileURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        recordBarButtonItem.isEnabled = false
        playBarButtonItem.isEnabled = false
        
        initializeAudioFileStorage()
        initializeAudioSession()
        
        audioSession?.requestRecordPermission() {
            [unowned self] allowed in
            if allowed {
                self.initializeAudioRecorder()
                guard let _ = self.audioSession, let _ = self.audioRecorder else {
                    self.presentAlert(message: "Unable to initialize audio.")
                    return
                }
                
                self.recordBarButtonItem.isEnabled = true
            } else {
                self.presentAlert(message: "Access to recording was denied.")
            }
        }

    }
    
    func initializeAudioFileStorage() {
        let fileManager = FileManager.default
        let documentDirectoryPaths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        documentDirectoryURL = documentDirectoryPaths[0]
        audioFileURL = documentDirectoryURL?.appendingPathComponent(audioFileName)
    }
    
    func initializeAudioSession() {
        audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession?.setCategory(.playAndRecord, mode: .default, options: [])
        } catch {
            presentAlert(message: "audioSession error: \(error.localizedDescription)")
        }
    }
    
    func initializeAudioRecorder() {
        let recordingSettings =
            [AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue,
             AVEncoderBitRateKey: 16,
             AVNumberOfChannelsKey: 2,
             AVSampleRateKey: 44100.0] as [String : Any]
        
        guard let audioFileURL = audioFileURL else {
            presentAlert(message: "No audio file URL is available.")
            return
        }
        
        do {
            try audioRecorder = AVAudioRecorder(url: audioFileURL, settings: recordingSettings)
            audioRecorder?.delegate = self
        } catch {
            presentAlert(message: "Error initializing the audio recorder: \(error.localizedDescription)")
        }
    }

    @IBAction func recordButtonTapped(_ sender: Any) {
        if (audioRecorder?.isRecording == false) {
            playBarButtonItem.isEnabled = false
            recordBarButtonItem.image = UIImage(named: "stop")
            audioRecorder?.record()
        } else {
            playBarButtonItem.isEnabled = true
            recordBarButtonItem.image = UIImage(named: "record")
            audioRecorder?.stop()
        }
    }
    
    @IBAction func playButtonTapped(_ sender: Any) {
        guard let audioFileURL = audioFileURL else {
            presentAlert(message: "Audio file is not available to play.")
            return
        }
        
        guard let audioRecorder = audioRecorder, audioRecorder.isRecording == false else {
            presentAlert(message: "Unable to play audio during recording.")
            return
        }
        
        if let audioPlayer = audioPlayer {
            if (audioPlayer.isPlaying) {
                audioPlayer.stop()
                playBarButtonItem.image = UIImage(named: "play")
                recordBarButtonItem.isEnabled = true
                return
            }
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioFileURL)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            recordBarButtonItem.isEnabled = false
            playBarButtonItem.image = UIImage(named: "stop")
        } catch {
            presentAlert(message: "Unable to create audio player.")
            return
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        recordBarButtonItem.isEnabled = true
        playBarButtonItem.image = UIImage(named: "play")
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        guard let error = error  else {
            return
        }
        presentAlert(message: "Audio play decoding error: \(error.localizedDescription)")
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        guard let error = error  else {
            return
        }
        presentAlert(message: "Audio record encoding error: \(error.localizedDescription)")
    }
    
    func presentAlert(message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
    
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
}
