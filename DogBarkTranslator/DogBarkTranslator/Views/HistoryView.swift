import SwiftUI

struct EditNotesView: View {
    let recording: Recording
    @Binding var isPresented: Bool
    @State private var notes: String
    @StateObject private var viewModel: HistoryViewModel
    var onSave: (String) -> Void
    
    init(recording: Recording, isPresented: Binding<Bool>, viewModel: HistoryViewModel, onSave: @escaping (String) -> Void) {
        self.recording = recording
        self._isPresented = isPresented
        self._notes = State(initialValue: recording.notes)
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                // Recording info section
                VStack(alignment: .leading, spacing: 8) {
                    Text(recording.title)
                        .font(.headline)
                    
                    ForEach(recording.predictions, id: \.self) { prediction in
                        Text(prediction)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(recording.timestamp, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Play/Stop Button
                    Button(action: {
                        Task {
                            if viewModel.currentlyPlayingID == recording.id {
                                await viewModel.stopPlayback()
                            } else {
                                await viewModel.playRecording(recording)
                            }
                        }
                    }) {
                        Label(
                            viewModel.currentlyPlayingID == recording.id ? "Stop" : "Play Recording",
                            systemImage: viewModel.currentlyPlayingID == recording.id ? "stop.circle.fill" : "play.circle.fill"
                        )
                        .font(.title3)
                        .foregroundColor(.blue)
                    }
                    .padding(.vertical, 4)
                }
                .padding(.horizontal)
                
                Divider()
                
                // Notes section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    TextEditor(text: $notes)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(8)
                        .scrollContentBackground(.hidden)
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
            .navigationTitle("Edit Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(notes)
                        isPresented = false
                    }
                }
            }
        }
    }
}

enum SortOption: String, CaseIterable {
    case dateNewest = "Newest First"
    case dateOldest = "Oldest First"
    case titleAZ = "Title A-Z"
    case titleZA = "Title Z-A"
}

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @State private var editingRecordingId: UUID?
    @State private var selectedSortOption = SortOption.dateNewest
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SearchBar(text: $viewModel.searchText)
                    .onChange(of: viewModel.searchText) { oldValue, newValue in
                        viewModel.updateFilteredRecordings()
                    }
                    .padding(.vertical, 8)
                
                List {
                    Section {
                        Picker("Sort by", selection: $selectedSortOption) {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    ForEach(viewModel.sortedRecordings(by: selectedSortOption)) { recording in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(recording.title)
                                .font(.headline)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    ForEach(recording.predictions, id: \.self) { prediction in
                                        Text(prediction)
                                            .font(.subheadline)
                                    }
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    editingRecordingId = recording.id
                                }) {
                                    Label("View Details", systemImage: "info.circle")
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            HStack {
                                Spacer()
                                Text(recording.timestamp, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if !recording.notes.isEmpty {
                                Text(recording.notes)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                            }
                            
                            if let photoURL = recording.photoURL,
                               let image = UIImage(contentsOfFile: photoURL.path) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 200)
                                    .cornerRadius(8)
                                    .padding(.top, 4)
                            }
                        }
                        .padding(.vertical, 8)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                        .listRowSeparator(.hidden)
                        .background(
                            VStack {
                                Spacer()
                                Divider()
                            }
                        )
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.deleteRecording(recording)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("History")
            .sheet(item: Binding(
                get: { editingRecordingId.flatMap { id in
                    viewModel.filteredRecordings.first { $0.id == id }
                }},
                set: { recording in
                    editingRecordingId = recording?.id
                }
            )) { recording in
                EditNotesView(
                    recording: recording,
                    isPresented: Binding(
                        get: { editingRecordingId != nil },
                        set: { if !$0 { editingRecordingId = nil }}
                    ),
                    viewModel: viewModel
                ) { notes in
                    viewModel.updateNotes(recordingId: recording.id, notes: notes)
                }
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.error?.localizedDescription ?? "Unknown error")
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search recordings", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    HistoryView()
} 

