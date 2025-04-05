import SwiftUI
import PhotosUI
import AVFoundation

struct SaveRecordingView: View {
    @Environment(\.dismiss) private var dismiss
    let predictions: [String]
    let audioURL: URL
    let onSave: (String, String, URL?) async -> Void
    
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoURL: URL?
    @State private var isSaving = false
    @State private var showingCamera = false
    @State private var showingPhotoOptions = false
    @State private var showingPhotoPicker = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Recording Details")) {
                    TextField("Title", text: $title)
                    
                    VStack(alignment: .leading) {
                        Text("Predictions:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ForEach(predictions, id: \.self) { prediction in
                            Text(prediction)
                                .font(.subheadline)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .scrollContentBackground(.hidden)
                }
                
                Button(action: {
                    showingPhotoOptions = true
                }) {
                    HStack {
                        Image(systemName: "photo")
                        Text("Add a Photo")
                    }
                    .foregroundColor(.blue)
                }
                .listRowSeparator(.hidden)
                
                if let photoURL = photoURL, let image = UIImage(contentsOfFile: photoURL.path) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(8)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())
                }
                
                if photoURL != nil {
                    Button(role: .destructive) {
                        photoURL = nil
                    } label: {
                        Text("Remove Photo")
                    }
                    .listRowSeparator(.hidden)
                }
                
                HStack(spacing: 16) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        isSaving = true
                        Task {
                            await onSave(title, notes, photoURL)
                            dismiss()
                        }
                    }) {
                        Text("Save")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(title.isEmpty || isSaving)
                }
                .padding(.horizontal)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            .actionSheet(isPresented: $showingPhotoOptions) {
                ActionSheet(title: Text("Add a Photo"), buttons: [
                    .default(Text("Use Camera")) {
                        showingCamera = true
                    },
                    .default(Text("Choose from Photos")) {
                        showingPhotoPicker = true
                    },
                    .cancel()
                ])
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(sourceType: .camera) { image in
                    if let image = image, let data = image.jpegData(compressionQuality: 0.8) {
                        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        let imageURL = documentsPath.appendingPathComponent("\(UUID().uuidString).jpg")
                        try? data.write(to: imageURL)
                        photoURL = imageURL
                    }
                    showingCamera = false
                }
            }
            .photosPicker(isPresented: $showingPhotoPicker,
                          selection: $selectedPhoto,
                          matching: .images,
                          photoLibrary: .shared())
            .navigationTitle("Save Recording")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    isSaving = true
                    Task {
                        await onSave(title, notes, photoURL)
                        dismiss()
                    }
                }
                .disabled(title.isEmpty || isSaving)
            )
            .onChange(of: selectedPhoto) { oldValue, newItem in
                guard let newItem else { return }
                Task {
                    do {
                        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        let imageURL = documentsPath.appendingPathComponent("\(UUID().uuidString).jpg")
                        
                        if let data = try? await newItem.loadTransferable(type: Data.self),
                           let _ = UIImage(data: data) {
                            try data.write(to: imageURL)
                            photoURL = imageURL     
                        }
                    } catch {
                        print("Error loading photo: \(error)")
                    }
                }
                showingPhotoPicker = false
            }
            .interactiveDismissDisabled()
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.onImagePicked(uiImage)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }

    @Environment(\.presentationMode) var presentationMode
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    var onImagePicked: (UIImage?) -> Void

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
} 
