import Foundation
import AVFoundation
import Combine

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var filteredRecordings: [Recording] = []
    @Published var isPlaying = false
    @Published var currentlyPlayingID: UUID?
    @Published var error: Error?
    
    private let recordingStore = RecordingStore.shared
    private let audioManager = AudioManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Initial load of recordings
        updateFilteredRecordings()
        
        // Observe RecordingStore changes
        recordingStore.$recordings
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateFilteredRecordings()
            }
            .store(in: &cancellables)
    }
    
    func updateFilteredRecordings() {
        if searchText.isEmpty {
            filteredRecordings = recordingStore.recordings
        } else {
            filteredRecordings = recordingStore.recordings.filter { recording in
                recording.predictions.joined(separator: " ")
                    .localizedCaseInsensitiveContains(searchText) ||
                recording.notes.localizedCaseInsensitiveContains(searchText) ||
                recording.title.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    func sortedRecordings(by option: SortOption) -> [Recording] {
        switch option {
        case .dateNewest:
            return filteredRecordings.sorted { $0.timestamp > $1.timestamp }
        case .dateOldest:
            return filteredRecordings.sorted { $0.timestamp < $1.timestamp }
        case .titleAZ:
            return filteredRecordings.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .titleZA:
            return filteredRecordings.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedDescending }
        }
    }
    
    func deleteRecording(_ recording: Recording) {
        if currentlyPlayingID == recording.id {
            Task {
                await stopPlayback()
            }
        }
        
        Task {
            do {
                try await recordingStore.deleteRecording(recording)
            } catch {
                self.error = error
            }
        }
    }
    
    @MainActor
    func playRecording(_ recording: Recording) async {
        do {
            if isPlaying {
                audioManager.stopPlayback()
                isPlaying = false
                currentlyPlayingID = nil
            }
            
            try audioManager.playRecording(url: recording.audioURL)
            isPlaying = true
            currentlyPlayingID = recording.id
            
            // Add completion handler
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task {
                    await self?.stopPlayback()
                }
            }
        } catch {
            self.error = error
        }
    }
    
    @MainActor
    func stopPlayback() async {
        audioManager.stopPlayback()
        isPlaying = false
        currentlyPlayingID = nil
        NotificationCenter.default.removeObserver(
            self,
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
    }
    
    func updateNotes(recordingId: UUID, notes: String) {
        Task {
            do {
                try await recordingStore.updateNotes(recordingId: recordingId, notes: notes)
            } catch {
                self.error = error
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
} 
