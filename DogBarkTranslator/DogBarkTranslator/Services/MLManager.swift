import Foundation
import CoreML
import AVFoundation

let baseURL = "http://192.168.2.20:8000" 

// The PredictionResult struct is used to decode backend responses
struct PredictionResult: Decodable {
    let context_prediction: String
    let name_prediction: String
    let breed_prediction: String

    enum CodingKeys: String, CodingKey {
        case context_prediction
        case name_prediction
        case breed_prediction
    }

    // Initialize PredictionResult from backend response (with labels)
    init(context_prediction: String, name_prediction: String, breed_prediction: String) {
        self.context_prediction = context_prediction
        self.name_prediction = name_prediction
        self.breed_prediction = breed_prediction
    }
}

class MLManager {
    static let shared = MLManager()
    
    private var contextModel: MLModel?
    private var breedModel: MLModel?
    private var nameModel: MLModel?
    
    private init() {
        loadModels()
    }
    
    private func loadModels() {
        // TODO: Load Core ML models (if needed)
        // Example:
        // self.contextModel = try? contextPredictor.model
        // self.breedModel = try? breedPredictor.model
        // self.nameModel = try? namePredictor.model
    }
    
    // Function to process audio and send it to the backend for prediction
    func processAudio(_ url: URL, for types: [String]) async throws -> [PredictionResult] {
        var results: [PredictionResult] = []
        
        // Loop over prediction types and request from the backend
        for type in types {
            let prediction = try await sendToBackend(audioURL: url, predictionType: type)
            switch type {
            case "Context":
                results.append(PredictionResult(context_prediction: prediction, name_prediction: "", breed_prediction: ""))
            case "Breed":
                results.append(PredictionResult(context_prediction: "", name_prediction: "", breed_prediction: prediction))
            case "Name":
                results.append(PredictionResult(context_prediction: "", name_prediction: prediction, breed_prediction: ""))
            default:
                break
            }
        }

        return results
    }

    // Function to send audio data to the backend and receive prediction
    private func sendToBackend(audioURL: URL, predictionType: String) async throws -> String {
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: "\(baseURL)/predict/")!)
        
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let audioData = try Data(contentsOf: audioURL)
        var body = Data()
        
        // Construct multipart form data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audioData) // Append the audio data
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"predict_type\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(predictionType)\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        // Perform the POST request
        let (data, _) = try await URLSession.shared.data(for: request)
        if let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let prediction = response["prediction"] {
            return "\(prediction)"
        } else {
            throw NSError(domain: "PredictionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid prediction"])
        }
    }

    // New feature to fetch a sample prediction
    func fetchSamplePrediction(for sampleName: String) async throws -> [PredictionResult] {
        guard let url = URL(string: "\(baseURL)/predict_sample/\(sampleName)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: String]
        let predictions = json?.map { PredictionResult(context_prediction: $0.key, name_prediction: "", breed_prediction: $0.value) } ?? []
        return predictions
    }

    // Helper methods for ML model predictions (can be replaced with actual model logic)
    private func extractAudioFeatures(from url: URL) async throws -> MLMultiArray {
        // TODO: Implement audio feature extraction logic (e.g., MEL spectrograms)
        return try MLMultiArray(shape: [1], dataType: .float32)
    }

    private func predictContext(features: MLMultiArray) async throws -> String? {
        // TODO: Implement context prediction with Core ML model
        return "Happy"
    }

    private func predictBreed(features: MLMultiArray) async throws -> String? {
        // TODO: Implement breed prediction with Core ML model
        return "Golden Retriever"
    }

    private func predictName(features: MLMultiArray) async throws -> String? {
        // TODO: Implement name prediction with Core ML model
        return "Max"
    }
}
