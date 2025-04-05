import Foundation
import AVFoundation
import Combine

enum AudioError: LocalizedError {
    case recordingFailed
    case playbackFailed
    case audioEngineFailed
    case noRecordingAvailable
    
    var errorDescription: String? {
        switch self {
        case .recordingFailed: return "Failed to start recording"
        case .playbackFailed: return "Failed to play audio"
        case .audioEngineFailed: return "Audio engine failed to start"
        case .noRecordingAvailable: return "No recording available"
        }
    }
}

class AudioManager: NSObject, ObservableObject {
    static let shared = AudioManager()
    
    @Published var isRecording = false
    @Published var audioLevel: Float = 0.0
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var levelTimer: Timer?
    var recordingURL: URL?
    
    override private init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    func startRecording() throws {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("\(UUID().uuidString).m4a")
        recordingURL = audioFilename
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.record()
        isRecording = true
        
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.audioRecorder?.updateMeters()
            self?.audioLevel = (self?.audioRecorder?.averagePower(forChannel: 0) ?? -160) + 160
            self?.audioLevel = max(0, min(self?.audioLevel ?? 0, 160))
            self?.audioLevel /= 160
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        levelTimer?.invalidate()
        levelTimer = nil
        isRecording = false
        audioLevel = 0
    }
    
    func playRecording(url: URL) throws {
        stopPlayback()
        
        let player = try AVAudioPlayer(contentsOf: url)
        player.delegate = self
        audioPlayer = player
        player.play()
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
}

extension AudioManager: AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        isRecording = false
        levelTimer?.invalidate()
        levelTimer = nil
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopPlayback()
    }
} 