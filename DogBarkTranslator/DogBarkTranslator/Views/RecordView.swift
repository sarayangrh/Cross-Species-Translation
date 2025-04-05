import SwiftUI

struct RecordView: View {
    @StateObject private var viewModel = RecordViewModel()
    @State private var showingError = false
    @State private var showingConfirmation = false
    @State private var showingSaveDialog = false
    @State private var showingCancelConfirmation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Header section with divider
                    VStack(spacing: 7) {
                        // Prediction Type Selection
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Select Prediction Types")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(Array(viewModel.predictionTypes.enumerated()), id: \.element.id) { index, type in
                                        Button(action: {
                                            viewModel.togglePredictionType(index)
                                        }) {
                                            Text(type.name)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .fill(type.isSelected ? Color.blue : Color.gray.opacity(0.2))
                                                )
                                                .foregroundColor(type.isSelected ? .white : .primary)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical, 16)
                    
                    Divider()
                        .background(Color.gray.opacity(0.2))
                    
                    // Main content
                    VStack(spacing: 0) {
                        // Selected Types Display
                        if !viewModel.getSelectedTypes().isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                Text("Selected: \(viewModel.getSelectedTypes().joined(separator: ", "))")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                            }
                        }
                        
                        Spacer()
                        
                        // Audio visualization
                        if viewModel.isRecording || viewModel.isProcessing {
                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .stroke(lineWidth: 8)
                                        .opacity(0.2)
                                        .foregroundColor(.blue)
                                    
                                    Circle()
                                        .trim(from: 0, to: min(CGFloat(viewModel.recordingDuration / viewModel.minimumRecordingDuration), 1.0))
                                        .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                        .foregroundColor(.blue)
                                        .rotationEffect(.degrees(-90))
                                    
                                    VStack {
                                        Text(String(format: "%d:%02d", Int(viewModel.recordingDuration) / 60, Int(viewModel.recordingDuration) % 60))
                                            .font(.system(size: 28, weight: .medium, design: .monospaced))
                                            .foregroundColor(.blue)
                                        
                                        if viewModel.recordingDuration < viewModel.minimumRecordingDuration {
                                            Text("\(Int(ceil(viewModel.minimumRecordingDuration - viewModel.recordingDuration)))s until minimum")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .frame(width: 200, height: 200)
                                
                                AudioLevelView(level: viewModel.audioLevel)
                                    .frame(height: 60)
                            }
                        } else {
                            Text("Ready to record\nTap to start (minimum 4s)")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Prediction result
                        if !viewModel.currentPrediction.isEmpty {
                            VStack(spacing: 16) {
                                Text("Prediction Result:")
                                    .font(.headline)
                                    .padding(.top)
                                ScrollView(.vertical, showsIndicators: false) {
                                    Text(viewModel.currentPrediction)
                                        .font(.subheadline)
                                        .lineSpacing(20)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxHeight: 200)
                                
                                HStack(spacing: 16) {
                                    Button(action: {
                                        viewModel.discardRecording()
                                    }) {
                                        Text("Cancel")
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.gray.opacity(0.2))
                                            .foregroundColor(.primary)
                                            .cornerRadius(8)
                                    }
                                    
                                    Button(action: {
                                        showingSaveDialog = true
                                    }) {
                                        Text("Save")
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                    }
                                }
                                .padding(.top)
                            }
                        }
                        
                        Spacer()
                        
                        // Record button and cancel button
                        HStack(spacing: 20) {
                            if viewModel.isRecording {
                                // Cancel button
                                Button(action: {
                                    showingCancelConfirmation = true
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 60, height: 60)
                                        
                                        Image(systemName: "xmark")
                                            .font(.system(size: 24, weight: .medium))
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                            
                            // Record button
                            Button(action: {
                                viewModel.toggleRecording()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(viewModel.isRecording ? Color.red : Color.blue)
                                        .frame(width: 80, height: 80)
                                    
                                    if viewModel.isRecording {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.white)
                                            .frame(width: 32, height: 32)
                                    } else {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 32, height: 32)
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 40)
                    }
                    .padding()
                    
                    Divider()
                        .background(Color.gray.opacity(0.2))
                }
            }
            .navigationTitle("Record")
            .alert("Error", isPresented: Binding(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.error?.localizedDescription ?? "Unknown error")
            }
            .confirmationDialog(
                "Save Recording?",
                isPresented: $showingConfirmation,
                titleVisibility: .visible
            ) {
                Button("Save") {
                    showingSaveDialog = true
                }
                Button("Discard", role: .destructive) {
                    viewModel.discardRecording()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Would you like to save this recording with its predictions?")
            }
            .sheet(isPresented: $showingSaveDialog) {
                SaveRecordingView(
                    predictions: viewModel.lastPredictions.map { $0.description },
                    audioURL: viewModel.lastRecordingURL!
                ) { title, notes, photoURL in
                    Task {
                        do {
                            try await RecordingStore.shared.addRecording(
                                audioURL: viewModel.lastRecordingURL!,
                                predictions: viewModel.lastPredictions,
                                title: title,
                                notes: notes,
                                photoURL: photoURL
                            )
                            showingSaveDialog = false
                            // Clear the state after saving
                            viewModel.currentPrediction = ""
                            viewModel.lastPredictions = []
                            viewModel.lastRecordingURL = nil
                        } catch {
                            print("Error saving recording: \(error)")
                        }
                    }
                }
            }
            .confirmationDialog(
                "Cancel Recording?",
                isPresented: $showingCancelConfirmation,
                titleVisibility: .visible
            ) {
                Button("Yes, Cancel", role: .destructive) {
                    viewModel.toggleRecording(forceStop: true)
                    if let audioURL = viewModel.lastRecordingURL {
                        try? FileManager.default.removeItem(at: audioURL)
                    }
                    viewModel.currentPrediction = ""
                    viewModel.lastPredictions = []
                    viewModel.lastRecordingURL = nil
                }
                Button("No, Continue Recording", role: .cancel) {}
            } message: {
                Text("Are you sure you want to cancel this recording?")
            }
            .onChange(of: viewModel.currentPrediction) { _, _ in
                // Empty handler since we don't need automatic confirmation
            }
        }
    }
}

struct AudioLevelView: View {
    let level: Float
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05, paused: false)) { timeline in
            GeometryReader { geometry in
                HStack(alignment: .center, spacing: 2) {
                    ForEach(0..<30) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.blue)
                            .frame(width: 3)
                            .frame(height: barHeight(at: index, geometry: geometry, date: timeline.date))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private func barHeight(at index: Int, geometry: GeometryProxy, date: Date) -> CGFloat {
        let normalizedLevel = CGFloat(max(-60, min(0, level))) + 60
        let percentage = normalizedLevel / 60
        let maxHeight = geometry.size.height * 0.8
        
        // Create a smooth wave effect
        let frequency: Double = 2.0
        let speed: Double = 3.0
        let phase = date.timeIntervalSinceReferenceDate * speed
        let x = Double(index) / 30.0
        
        // Combine two waves for more natural movement
        let wave1 = sin(2 * .pi * frequency * x + phase)
        let wave2 = sin(2 * .pi * (frequency * 0.5) * x + phase * 0.5)
        let combinedWave = (wave1 + wave2) / 2.5
        
        return maxHeight * (0.3 + percentage * 0.7) * (combinedWave + 1) / 2
    }
}

#Preview {
    RecordView()
} 
