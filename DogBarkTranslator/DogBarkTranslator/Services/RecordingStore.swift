import Foundation

@MainActor
class RecordingStore: ObservableObject {
    static let shared = RecordingStore()
    
    @Published private(set) var recordings: [Recording] = []
    private let recordingsKey = "SavedRecordings"
    
    private init() {
        loadRecordings()
    }
    
    func addRecording(audioURL: URL, predictions: [PredictionResult], title: String, notes: String, photoURL: URL?) async throws {
        // Copy audio file to permanent storage
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let permanentURL = documentsPath.appendingPathComponent(audioURL.lastPathComponent)
        
        if permanentURL != audioURL {
            try FileManager.default.copyItem(at: audioURL, to: permanentURL)
        }
        
        // Copy photo if exists
        var finalPhotoURL: URL? = nil
        if let photoURL = photoURL {
            let newPhotoURL = documentsPath.appendingPathComponent("photos/\(UUID().uuidString).jpg")
            try FileManager.default.createDirectory(at: newPhotoURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: photoURL, to: newPhotoURL)
            finalPhotoURL = newPhotoURL
        }
        
        // Create and save recording
        let recording = Recording(
            id: UUID(),
            timestamp: Date(),
            audioURL: permanentURL,
            predictions: formatPredictionResults(predictions), // Use the new helper function
            title: title,
            notes: notes,
            photoURL: finalPhotoURL
        )
        
        recordings.insert(recording, at: 0)
        try await saveRecordings()
    }

// Helper function to format PredictionResult objects to a string
private func formatPredictionResults(_ predictions: [PredictionResult]) -> [String] {
    return predictions.map { result in
        var resultStr = ""
        if !result.context_prediction.isEmpty {
            resultStr += "Context: \(result.context_prediction)"
        }
        if !result.name_prediction.isEmpty {
            resultStr += "\nName: \(result.name_prediction)"
        }
        if !result.breed_prediction.isEmpty {
            resultStr += "\nBreed: \(result.breed_prediction)"
        }
        return resultStr
    }
}

    
    func deleteRecording(_ recording: Recording) async throws {
        // Delete audio file
        try FileManager.default.removeItem(at: recording.audioURL)
        
        // Delete photo if exists
        if let photoURL = recording.photoURL {
            try? FileManager.default.removeItem(at: photoURL)
        }
        
        // Remove from recordings array
        if let index = recordings.firstIndex(where: { $0.id == recording.id }) {
            recordings.remove(at: index)
            try await saveRecordings()
        }
    }
    
    func updateNotes(recordingId: UUID, notes: String) async throws {
        if let index = recordings.firstIndex(where: { $0.id == recordingId }) {
            var updatedRecording = recordings[index]
            updatedRecording.notes = notes
            recordings[index] = updatedRecording
            try await saveRecordings()
        }
    }
    
    private func loadRecordings() {
        guard let data = UserDefaults.standard.data(forKey: recordingsKey),
              let decodedRecordings = try? JSONDecoder().decode([Recording].self, from: data) else {
            return
        }
        
        // Filter out recordings whose audio files no longer exist
        recordings = decodedRecordings.filter { FileManager.default.fileExists(atPath: $0.audioURL.path) }
    }
    
    private func saveRecordings() async throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(recordings)
        UserDefaults.standard.set(data, forKey: recordingsKey)
    }
} 