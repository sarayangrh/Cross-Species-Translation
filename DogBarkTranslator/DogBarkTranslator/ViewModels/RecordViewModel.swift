import Foundation
import AVFoundation

struct PredictionType: Identifiable, Hashable {
    let id = UUID()
    let name: String
    var isSelected: Bool
    
    static let allTypes = [
        PredictionType(name: "Context", isSelected: false),
        PredictionType(name: "Breed", isSelected: false),
        PredictionType(name: "Name", isSelected: false)
    ]
}

@MainActor
class RecordViewModel: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var predictionTypes: [PredictionType]
    @Published var currentPrediction: String = ""
    @Published var audioLevel: Float = 0.0
    @Published var error: Error?
    @Published var isProcessing = false
    @Published var showingSaveDialog = false
    @Published var lastPredictions: [PredictionResult] = []
    @Published var lastRecordingURL: URL?
    @Published var recordingDuration: TimeInterval = 0
    
    private let audioManager = AudioManager.shared
    private let mlManager = MLManager.shared
    private let recordingStore = RecordingStore.shared
    private var recordingTimer: Timer?
    let minimumRecordingDuration: TimeInterval = 4.0
    
    override init() {
        self.predictionTypes = PredictionType.allTypes
        super.init()
        setupAudioBindings()
    }
    
    private func setupAudioBindings() {
        // Bind audio manager's recording state and level to our view model
        audioManager.$isRecording.assign(to: &$isRecording)
        audioManager.$audioLevel.assign(to: &$audioLevel)
    }
    
    private func startRecordingTimer() {
        recordingDuration = 0
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.recordingDuration += 0.1
            }
        }
    }
    
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    func togglePredictionType(_ index: Int) {
        predictionTypes[index].isSelected.toggle()
    }
    
    func getSelectedTypes() -> [String] {
        return predictionTypes.filter { $0.isSelected }.map { $0.name }
    }
    
    func toggleRecording(forceStop: Bool = false) {
        guard !getSelectedTypes().isEmpty else {
            error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Please select at least one prediction type"])
            return
        }
        
        do {
            if isRecording {
                if !forceStop && recordingDuration < minimumRecordingDuration {
                    error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Please record for at least \(Int(minimumRecordingDuration)) seconds"])
                    return
                }
                stopRecordingTimer()
                audioManager.stopRecording()
                if !forceStop, let recordingURL = audioManager.recordingURL {
                    Task {
                        await processPrediction(for: recordingURL)
                    }
                }
            } else {
                try audioManager.startRecording()
                startRecordingTimer()
                currentPrediction = ""
                error = nil
                lastPredictions = []
                lastRecordingURL = nil
                showingSaveDialog = false
            }
        } catch {
            self.error = error
        }
    }
    
    private func processPrediction(for audioURL: URL) async {
        isProcessing = true
        do {
            let selectedTypes = getSelectedTypes()
            let predictions = try await mlManager.processAudio(audioURL, for: selectedTypes)
            
            // Format the prediction results for display
            currentPrediction = formatPredictionResults(predictions)
            lastPredictions = predictions
            lastRecordingURL = audioURL
        } catch {
            self.error = error
        }
        isProcessing = false
    }


    //new feature
    func predictFromSample(named sampleName: String) async {
        isProcessing = true
        currentPrediction = ""
        error = nil
        lastPredictions = []
        
        do {
            let predictions = try await mlManager.fetchSamplePrediction(for: sampleName)
            
            // Format the prediction results for display
            currentPrediction = formatPredictionResults(predictions)
            lastPredictions = predictions
        } catch {
            self.error = error
        }

        isProcessing = false
    }

    // New helper function to format prediction results
    private func formatPredictionResults(_ predictions: [PredictionResult]) -> String {
        return predictions.map { result in
            // Access properties of PredictionResult directly
            var resultStr = ""
            if !result.context_prediction.isEmpty {
                resultStr += "Context: \(result.context_prediction)\n"
            }
            if !result.name_prediction.isEmpty {
                resultStr += "Name: \(result.name_prediction)\n"
            }
            if !result.breed_prediction.isEmpty {
                resultStr += "Breed: \(result.breed_prediction)\n"
            }
            return resultStr
        }.joined(separator: "\n")
    }

    
    func saveRecording(title: String, notes: String, photoURL: URL?) async {
        guard let audioURL = lastRecordingURL else { return }
        
        do {
            try await recordingStore.addRecording(
                audioURL: audioURL,
                predictions: lastPredictions,
                title: title,
                notes: notes,
                photoURL: photoURL
            )
            // Clear the current state
            currentPrediction = ""
            lastPredictions = []
            lastRecordingURL = nil
        } catch {
            self.error = error
        }
    }
    
    func discardRecording() {
        if let audioURL = lastRecordingURL {
            try? FileManager.default.removeItem(at: audioURL)
        }
        currentPrediction = ""
        lastPredictions = []
        lastRecordingURL = nil
    }
} 
