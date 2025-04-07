import Foundation
import CoreML
import AVFoundation

enum PredictionResult {
    case context(String)
    case breed(String)
    case name(String)
    
    var description: String {
        switch self {
        case .context(let result): return "Context: \(result)"
        case .breed(let result): return "Breed: \(result)"
        case .name(let result): return "Name: \(result)"
        }
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
        // TODO: Load Core ML models
        // self.contextModel = try? contextPredictor.model
        // self.breedModel = try? breedPredictor.model
        // self.nameModel = try? namePredictor.model
    }
    
    func processAudio(_ url: URL, for types: [String]) async throws -> [PredictionResult] {
        var results: [PredictionResult] = []
        
        for type in types {
            let prediction = try await sendToBackend(audioURL: url, predictionType: type)
            switch type {
            case "Context": results.append(.context(prediction))
            case "Breed": results.append(.breed(prediction))
            case "Name": results.append(.name(prediction))
            default: break
            }
        }

        return results
        /**
        // Convert audio to required format for ML models
        let audioFeatures = try await extractAudioFeatures(from: url)
        
        for type in types {
            switch type {
            case "Context":
                if let prediction = try await predictContext(features: audioFeatures) {
                    results.append(.context(prediction))
                }
            case "Breed":
                if let prediction = try await predictBreed(features: audioFeatures) {
                    results.append(.breed(prediction))
                }
            case "Name":
                if let prediction = try await predictName(features: audioFeatures) {
                    results.append(.name(prediction))
                }
            default:
                break
            }
        }
        
        return results
        **/
    }

    private func sendToBackend(audioURL: URL, predictionType: String) async throws -> String {
        let boundary = UUID().uuidString
        //var request = URLRequest(url: URL(string: "http://127.0.0.1:8000/predict/")!)
        var request = URLRequest(url: URL(string: "http://localhost:8000/predict/")!)

        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let audioData = try Data(contentsOf: audioURL)
        var body = Data()

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\n")
        body.append("Content-Type: audio/wav\r\n\r\n")
        body.append(audioData)
        body.append("\r\n")

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"predict_type\"\r\n\r\n")
        body.append("\(predictionType)\r\n")
        body.append("--\(boundary)--\r\n")

        request.httpBody = body

        let (data, _) = try await URLSession.shared.data(for: request)
        if let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let prediction = response["prediction"] {
            return "\(prediction)"
        } else {
            throw NSError(domain: "PredictionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid prediction"])
        }
    }
    
    private func extractAudioFeatures(from url: URL) async throws -> MLMultiArray {
        // TODO: Implement audio feature extraction
        // This would include:
        // 1. Loading audio file
        // 2. Converting to required format (e.g., MEL spectrograms)
        // 3. Normalizing the data
        // 4. Creating MLMultiArray for model input
        return try MLMultiArray(shape: [1], dataType: .float32)
    }
    
    private func predictContext(features: MLMultiArray) async throws -> String? {
        // TODO: Implement context prediction using Core ML model
        return "Happy"
    }
    
    private func predictBreed(features: MLMultiArray) async throws -> String? {
        // TODO: Implement breed prediction using Core ML model
        return "Golden Retriever"
    }
    
    private func predictName(features: MLMultiArray) async throws -> String? {
        // TODO: Implement name prediction using Core ML model
        return "Max"
    }
} 