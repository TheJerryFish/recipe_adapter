//
//  UploadView.swift
//  recipe_adapter
//
//  Created by Jerry on 6/21/25.
//

import Foundation
import SwiftUI
import Vision
import PDFKit
import AVFoundation
import UIKit
import UniformTypeIdentifiers
import CoreML
import SentencepieceTokenizer

struct UploadView: View {
    @Binding var selectedImage: UIImage?
    @Binding var categorizedRecipes: [String: [RecipeData]]
    @Binding var isImagePickerPresented: Bool

    @State private var isCategoryPickerPresented = false
    @State private var selectedCategory: String = "Uncategorized"
    @State private var selectedFileURL: URL?
    @State private var selectedVideoURL: URL?
    @State private var isUploadOptionsPresented = false
    @State private var isDocumentPickerPresented = false
    @State private var isVideoPickerPresented = false
    @State private var pendingCategory: String?
    @State private var pendingImage: UIImage?

    var body: some View {
        VStack {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                    .padding()
            } else {
                Text("No image selected.")
                    .foregroundColor(.gray)
                    .padding()
            }

            Button("Upload Recipe") {
                isUploadOptionsPresented = true
            }
            .padding()
            .actionSheet(isPresented: $isUploadOptionsPresented) {
                ActionSheet(
                    title: Text("Select Upload Type"),
                    buttons: [
                        .default(Text("Image")) {
                            isImagePickerPresented = true
                        },
                        .default(Text("PDF/TXT File")) {
                            isDocumentPickerPresented = true
                        },
                        .default(Text("Video")) {
                            isVideoPickerPresented = true
                        },
                        .cancel()
                    ]
                )
            }
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker(image: $selectedImage)
            }
            .sheet(isPresented: $isDocumentPickerPresented) {
                DocumentPicker(image: $selectedImage) { urls in
                    if let url = urls.first {
                        selectedFileURL = url
                    }
                }
            }
            .sheet(isPresented: $isVideoPickerPresented) {
                VideoPicker { url in
                    extractFramesAndRecognizeText(from: url)
                }
            }

            if selectedImage != nil || selectedFileURL != nil {
                Button("Save to Recipes") {
                    isCategoryPickerPresented = true
                }
                .sheet(isPresented: $isCategoryPickerPresented) {
                    VStack(spacing: 20) {
                        Text("Choose or Enter Category")
                            .font(.headline)

                        HStack {
                            TextField("Enter or select category", text: $selectedCategory)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Menu {
                                ForEach(Array(categorizedRecipes.keys), id: \.self) { key in
                                    Button(key) {
                                        selectedCategory = key
                                    }
                                }
                            } label: {
                                Image(systemName: "chevron.down")
                                    .padding(.horizontal)
                            }
                        }
                        .padding()

                        Button("Confirm Save") {
                            pendingCategory = selectedCategory
                            if let fileURL = selectedFileURL {
                                handleFileUpload(from: fileURL, image: selectedImage)
                                selectedFileURL = nil
                                selectedImage = nil
                            } else if let image = selectedImage {
                                pendingImage = image
                                recognizeText(image: image)
                                selectedImage = nil
                            }
                            isCategoryPickerPresented = false
                        }

                        Button("Cancel", role: .cancel) {
                            isCategoryPickerPresented = false
                        }
                    }
                    .padding()
                }
                .padding()
            }
        }
    }
    
    func runIngredientParser(with text: String) {
        let lines = text.split(separator: "\n").map { String($0) }

        classifyLines(lines) { result in
            guard let result = result else {
                print("Classification failed")
                return
            }

            var ingredients: [String] = []
            var instructions: [String] = []

            for item in result {
                let label = item["label"] ?? ""
                let line = item["line"] ?? ""

                switch label {
                case "ingredient":
                    ingredients.append(line)
                case "instruction":
                    instructions.append(line)
                default:
                    break
                }
            }

            print("=== INGREDIENTS ===")
            for ing in ingredients {
                print("- \(ing)")
            }

            print("\n=== INSTRUCTIONS ===")
            for (index, step) in instructions.enumerated() {
                print("\(index + 1). \(step)")
            }
        }
    }
    
    func recognizeText(image: UIImage) {
        guard let cgImage = image.cgImage else {
            print("Invalid image")
            return
        }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { (request, error) in
            guard error == nil else {
                print("Error recognizing text: \(error!.localizedDescription)")
                return
            }

            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            let recognizedText = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
            print("OCR recognized text:\n\(recognizedText)")
            let lines = recognizedText.split(separator: "\n").map { String($0) }

            classifyLines(lines) { result in
                guard let result = result else {
                    print("Classification failed")
                    return
                }
                saveRecipe(from: result, image: self.pendingImage, category: self.pendingCategory ?? "Uncategorized")
                self.pendingImage = nil
                self.pendingCategory = nil
            }
        }

        request.recognitionLevel = .accurate

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                print("Failed to perform text recognition: \(error.localizedDescription)")
            }
        }
    }
    
    func saveRecipe(from result: [[String: String]], image: UIImage?, category: String) {
        var ingredients: [String] = []
        var instructions: [String] = []

        for item in result {
            let label = item["label"] ?? ""
            let line = item["line"] ?? ""

            switch label {
            case "ingredient":
                ingredients.append(line)
            case "instruction":
                instructions.append(line)
            default:
                break
            }
        }

        DispatchQueue.main.async {
            let recipeData = RecipeData(
                image: image!,
                ingredients: ingredients,
                instructions: instructions
            )
            if categorizedRecipes[category] == nil {
                categorizedRecipes[category] = []
            }
            categorizedRecipes[category]?.append(recipeData)
        }

        print("=== INGREDIENTS ===")
        ingredients.forEach { print("- \($0)") }

        print("=== INSTRUCTIONS ===")
        for (i, step) in instructions.enumerated() {
            print("\(i + 1). \(step)")
        }
    }
    
    func handleFileUpload(from url: URL, image: UIImage?) {
        if url.pathExtension.lowercased() == "pdf", let pdf = PDFDocument(url: url) {
            performAggregatedOCROnPDF(pdf, image: image, category: pendingCategory ?? "Uncategorized")
        } else if url.pathExtension.lowercased() == "txt" {
            let extractedText = (try? String(contentsOf: url)) ?? ""
            print("Extracted Text from TXT:\n\(extractedText)")
            runIngredientParserAndSave(text: extractedText, image: image, category: pendingCategory ?? "Uncategorized")
        } else {
            print("Unsupported file type.")
        }
    }
    
    func extractFramesAndRecognizeText(from url: URL) {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true

        let duration = CMTimeGetSeconds(asset.duration)
        let interval = max(1.0, duration / 5.0) // extract 5 frames at most
        let times = stride(from: 0.0, to: duration, by: interval).map {
            NSValue(time: CMTimeMakeWithSeconds($0, preferredTimescale: 600))
        }

        generator.generateCGImagesAsynchronously(forTimes: times) { _, imageRef, _, _, error in
            if let imageRef = imageRef {
                let uiImage = UIImage(cgImage: imageRef)
                recognizeText(image: uiImage)
            } else if let error = error {
                print("Frame extraction error: \(error)")
            }
        }
    }
    
    func performAggregatedOCROnPDF(_ pdf: PDFDocument, image: UIImage?, category: String) {
        var recognizedText = ""
        let dispatchGroup = DispatchGroup()

        for i in 0..<pdf.pageCount {
            guard let page = pdf.page(at: i) else { continue }
            let imageThumb = page.thumbnail(of: CGSize(width: 1000, height: 1000), for: .mediaBox)
            guard let cgImage = imageThumb.cgImage else { continue }

            dispatchGroup.enter()

            let request = VNRecognizeTextRequest { request, error in
                defer { dispatchGroup.leave() }

                guard error == nil,
                      let observations = request.results as? [VNRecognizedTextObservation] else {
                    print("OCR error on page \(i): \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                let pageText = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")

                recognizedText += pageText + "\n"
            }

            request.recognitionLevel = .accurate
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    print("Failed to perform OCR on page \(i): \(error.localizedDescription)")
                    dispatchGroup.leave()
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            print("Aggregated OCR Text:\n\(recognizedText)")
            runIngredientParserAndSave(text: recognizedText, image: image, category: category)
        }
    }

    func runIngredientParserAndSave(text: String, image: UIImage?, category: String) {
        let lines = text.split(separator: "\n").map { String($0) }
        classifyLines(lines) { result in
            guard let result = result else {
                print("Classification failed")
                return
            }
            saveRecipe(from: result, image: image, category: category)
            self.pendingImage = nil
            self.pendingCategory = nil
        }
    }
    
}

#Preview {
    UploadView(
        selectedImage: .constant(nil),
        categorizedRecipes: .constant([:]),
        isImagePickerPresented: .constant(false)
    )
}

extension MLMultiArray {
    static func from(_ intArray: [Int32]) -> MLMultiArray {
        let shape: [NSNumber] = [1, NSNumber(value: intArray.count)]
        let mlArray = try! MLMultiArray(shape: shape, dataType: .int32)
        for (i, value) in intArray.enumerated() {
            mlArray[i] = NSNumber(value: value)
        }
        return mlArray
    }
}

func classifyLines(_ lines: [String], completion: @escaping ([[String: String]]?) -> Void) {
    guard let modelURL = Bundle.main.url(forResource: "mt5_encoder", withExtension: "mlmodelc"),
          let model = try? MLModel(contentsOf: modelURL),
          let spiecePath = Bundle.main.path(forResource: "spiece", ofType: "model") else {
        if Bundle.main.url(forResource: "mt5_encoder", withExtension: "mlmodelc") == nil {
            print("Model not found in bundle.")
        }
        if Bundle.main.path(forResource: "spiece", ofType: "model") == nil {
            print("SentencePiece model not found in bundle.")
        }
        print("Failed to load model or SentencePiece.")
        completion(nil)
        return
    }

    guard let processor = try? SentencepieceTokenizer(modelPath: spiecePath) else {
        print("Failed to initialize SentencePiece processor.")
        completion(nil)
        return
    }

    func encodeWithSentencePiece(_ line: String, maxLength: Int = 128) -> [Int64] {
        var tokenIds: [Int64]
        do {
            tokenIds = try processor.encode(line).map { Int64($0) }
        } catch {
            print("Tokenization failed: \(error.localizedDescription)")
            tokenIds = []
        }
        // Append </s> if needed (usually id 1)
        tokenIds.append(1)
        if tokenIds.count < maxLength {
            tokenIds += Array(repeating: 0, count: maxLength - tokenIds.count)  // pad with <pad> = 0
        } else if tokenIds.count > maxLength {
            tokenIds = Array(tokenIds.prefix(maxLength))
        }
        return tokenIds
    }

    var results: [[String: String]] = []
    print("Classifying lines: \(lines)")
    let dispatchGroup = DispatchGroup()
    let resultLock = NSLock()

    let operationQueue = OperationQueue()
    operationQueue.qualityOfService = .userInitiated
    operationQueue.maxConcurrentOperationCount = 3

    for line in lines {
        dispatchGroup.enter()
        operationQueue.addOperation {
            autoreleasepool {
                defer { dispatchGroup.leave() }
                print("Classifying line: \"\(line)\"")
                do {
                    let input_ids = encodeWithSentencePiece(line)
                    let inputFeatures = try MLDictionaryFeatureProvider(dictionary: [
                        "input_ids": MLMultiArray.from(input_ids.map(Int32.init))
                    ])
                    let prediction = try model.prediction(from: inputFeatures)
                    print("Raw prediction: \(prediction)")
                    if let label = prediction.featureValue(for: "label")?.stringValue {
                        print("→ Result: \(label)")
                        resultLock.lock()
                        results.append(["label": label, "line": line])
                        resultLock.unlock()
                    }
                } catch {
                    print("Prediction failed for line '\(line)': \(error.localizedDescription)")
                }
            }
        }
    }

    dispatchGroup.notify(queue: .main) {
        completion(results)
    }
}

