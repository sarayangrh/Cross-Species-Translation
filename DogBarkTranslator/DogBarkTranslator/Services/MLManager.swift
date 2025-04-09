import Foundation
import CoreML
import AVFoundation

// Try multiple possible URLs for the API server
let possibleBaseURLs = ["http://localhost:8000", "http://127.0.0.1:8000", "http://192.168.2.20:8000"]
let baseURL = possibleBaseURLs[0] // Start with the first one

// The PredictionResult struct is used to decode backend responses
struct PredictionResult: Decodable, Hashable {
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
    
    // Add a description computed property to make it easier to display the results
    var description: String {
        var result = ""
        if !context_prediction.isEmpty {
            result += "Context: \(context_prediction)"
        }
        if !breed_prediction.isEmpty {
            if !result.isEmpty { result += ", " }
            result += "Breed: \(breed_prediction)"
        }
        if !name_prediction.isEmpty {
            if !result.isEmpty { result += ", " }
            result += "Name: \(name_prediction)"
        }
        return result
    }
}

class MLManager {
    static let shared = MLManager()
    
    private var contextModel: MLModel?
    private var breedModel: MLModel?
    private var nameModel: MLModel?
    private var currentBaseURLIndex = 0
    
    private var currentBaseURL: String {
        return possibleBaseURLs[currentBaseURLIndex]
    }
    
    private func tryNextServer() {
        currentBaseURLIndex = (currentBaseURLIndex + 1) % possibleBaseURLs.count
        print("Switching to server: \(currentBaseURL)")
    }
    
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
        
        do {
            // Loop over prediction types and request from the backend
            for type in types {
                do {
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
                } catch {
                    print("Error processing \(type): \(error)")
                    // Add fallback data in case of error
                    switch type {
                    case "Context":
                        results.append(PredictionResult(context_prediction: "Happy (Demo)", name_prediction: "", breed_prediction: ""))
                    case "Breed":
                        results.append(PredictionResult(context_prediction: "", name_prediction: "", breed_prediction: "Golden Retriever (Demo)"))
                    case "Name":
                        results.append(PredictionResult(context_prediction: "", name_prediction: "Max (Demo)", breed_prediction: ""))
                    default:
                        break
                    }
                }
            }
            
            // If no results were added, throw an error
            if results.isEmpty {
                throw NSError(domain: "PredictionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No predictions were generated"])
            }
            
            return results
        } catch {
            print("Process audio error: \(error)")
            // Provide demo data as fallback when all else fails
            let demoResult = PredictionResult(
                context_prediction: types.contains("Context") ? "Happy (Demo)" : "",
                name_prediction: types.contains("Name") ? "Max (Demo)" : "",
                breed_prediction: types.contains("Breed") ? "Golden Retriever (Demo)" : ""
            )
            return [demoResult]
        }
    }

    // Function to send audio data to the backend and receive prediction
    private func sendToBackend(audioURL: URL, predictionType: String) async throws -> String {
        // Try each server URL
        for _ in 0..<possibleBaseURLs.count {
            print("Sending prediction request to \(currentBaseURL)/predict/ for type: \(predictionType)")
            
            do {
                let boundary = UUID().uuidString
                guard let url = URL(string: "\(currentBaseURL)/predict/") else {
                    tryNextServer()
                    continue
                }
                
                var request = URLRequest(url: url)
                request.timeoutInterval = 5 // Shorter timeout for faster fallback
                
                request.httpMethod = "POST"
                request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                
                let audioData = try Data(contentsOf: audioURL)
                print("Audio data size: \(audioData.count) bytes")
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
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    print("Server returned error code: \(httpResponse.statusCode)")
                    tryNextServer()
                    continue
                }
                
                print("API Response: \(response)")
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response data: \(responseString)")
                }
                
                if let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let prediction = response["prediction"] {
                    print("Prediction result: \(prediction)")
                    return "\(prediction)"
                }
            } catch {
                print("Error with server \(currentBaseURL): \(error)")
                tryNextServer()
                continue
            }
            
            // If we get here, try next server
            tryNextServer()
        }
        
        // If all servers failed, return mock data
        print("All servers failed, returning mock data")
        return "\(predictionType) prediction (demo)"
    }

    // New feature to fetch a sample prediction
    func fetchSamplePrediction(for sampleName: String) async throws -> [PredictionResult] {
        guard let url = URL(string: "\(currentBaseURL)/predict_sample/\(sampleName)") else {
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
