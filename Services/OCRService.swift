import Foundation
import UIKit
import Vision

public class OCRService {
    public init() {}

    public func recognizeText(from image: UIImage, completion: @escaping ([String]) -> Void) {
        guard let cgImage = image.cgImage else { completion([]); return }
        let request = VNRecognizeTextRequest { request, error in
            guard error == nil else { completion([]); return }
            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            let texts = observations.compactMap { $0.topCandidates(1).first?.string }
            completion(texts)
        }
        request.recognitionLevel = .accurate
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                completion([])
            }
        }
    }
}
