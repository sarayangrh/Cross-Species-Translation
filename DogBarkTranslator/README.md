# DogBarkTranslator iOS App

## Project Overview
DogBarkTranslator is an iOS application that records dog barks and translates them into predictions about the dog's context, breed, and name. The front-end is complete and ready for ML model integration.

## Project Structure

```
DogBarkTranslator/
├── Views/
│   ├── RecordView.swift         # Main recording interface
│   ├── HistoryView.swift        # Recording history
│   ├── SaveRecordingView.swift  # Save dialog
│   └── SettingsView.swift       # App settings
├── ViewModels/
│   ├── RecordViewModel.swift    # Recording logic
│   └── HistoryViewModel.swift   # History management
├── Models/
│   └── Recording.swift          # Data model
├── Services/
│   ├── AudioManager.swift       # Audio recording/playback
│   ├── MLManager.swift          # ML integration point
│   └── RecordingStore.swift     # Data persistence
└── Assets.xcassets/             # App icons and resources
```

## Integration Points

### 1. ML Integration (MLManager.swift)
This is the main integration point for the ML model. Key areas to implement:

```swift
class MLManager {
    func processAudio(_ url: URL, for types: [String]) async throws -> [PredictionResult]
}
```
- Input: Audio file URL and requested prediction types
- Output: Array of predictions
- Supported prediction types: "Context", "Breed", "Name"

### 2. Audio Recording (AudioManager.swift)
Handles audio recording and playback:
- Recording format: WAV
- Minimum duration: 10 seconds
- Access to raw audio data for ML processing

### 3. Data Storage (RecordingStore.swift)
Manages persistence of:
- Audio recordings
- Prediction results
- Optional photos
- Notes and metadata

## Key Features

1. Recording:
   - Minimum 10-second recording requirement
   - Visual audio level visualization
   - Progress indicator
   - Cancel with confirmation

2. Prediction Types:
   - Context: Dog's emotional/situational context
   - Breed: Dog breed prediction
   - Name: Suggested dog name
   - Multiple types can be selected simultaneously

3. Results Storage:
   - Local storage of recordings
   - Photo attachment support
   - Notes and title for each recording
   - Searchable history

## Integration Steps

1. ML Model Integration:
   - Implement `processAudio` in MLManager
   - Handle audio processing
   - Return predictions in the correct format

2. Backend Connection:
   - Add network layer if needed
   - Implement API calls
   - Handle authentication if required

3. Error Handling:
   - Network errors
   - ML processing errors
   - Invalid audio format

## Data Formats

### Prediction Result Format:
```swift
struct PredictionResult {
    let type: String      // "Context", "Breed", or "Name"
    let value: String     // The actual prediction
    var confidence: Float // Optional confidence score
}
```

### Recording Model:
```swift
struct Recording {
    let id: UUID
    let timestamp: Date
    let audioURL: URL
    let predictions: [String]
    var title: String
    var notes: String
    var photoURL: URL?
}
```

## Getting Started

1. Clone the repository
2. Open `DogBarkTranslator.xcodeproj` in Xcode
3. Build and run on iOS 17.0 or later
4. Implement ML integration in `MLManager.swift`

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- Microphone permission
- Photo library permission (optional)

## Notes for Integration

- The app uses async/await for asynchronous operations
- All ML processing should be done asynchronously
- Handle memory management for large audio files
- Consider adding progress updates for long-running ML tasks
- Implement proper error handling and user feedback

## Testing

- Test with various audio lengths (minimum 10 seconds)
- Test all prediction type combinations
- Verify error handling and edge cases
- Test with different audio qualities and environments

For any questions or clarification, please contact [Your Contact Info]. 