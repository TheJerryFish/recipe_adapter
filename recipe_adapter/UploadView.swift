//
//  UploadView.swift
//  recipe_adapter
//
//  Created by Jerry on 6/21/25.
//

import Foundation
import SwiftUI
import Vision

struct UploadView: View {
    @Binding var selectedImage: UIImage?
    @Binding var categorizedRecipes: [String: [RecipeData]]
    @Binding var isImagePickerPresented: Bool

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
                isImagePickerPresented = true
            }
            .padding()
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker(image: $selectedImage)
            }

            if selectedImage != nil {
                Button("Save to Recipes") {
                    if let image = selectedImage {
                        recognizeTextAndSave(image: image)
                        selectedImage = nil
                    }
                }
                .padding()
            }
        }
    }

    func recognizeText(from image: UIImage) {
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

            if recognizedText.isEmpty {
                print("No Text Found")
            } else {
                print("Recognized Text:\n\(recognizedText)")
                runIngredientParser(with: recognizedText)
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
    
    func runIngredientParser(with text: String) {
        let result = extractIngredientsAndInstructions(from: text)
        
        print("=== INGREDIENTS ===")
        for ing in result.ingredients {
            print("- \(ing)")
        }

        print("\n=== INSTRUCTIONS ===")
        for (index, step) in result.instructions.enumerated() {
            print("\(index + 1). \(step)")
        }
    }
    
    func recognizeTextAndSave(image: UIImage) {
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

            let parsed = extractIngredientsAndInstructions(from: recognizedText)

            classifyLines(parsed.ingredients + parsed.instructions) { result in
                guard let result = result else {
                    print("Classification failed")
                    return
                }

                for item in result {
                    print("Line: \(item["line"] ?? "") -> Label: \(item["label"] ?? "")")
                }
            }

            DispatchQueue.main.async {
                let recipeData = RecipeData(
                    image: image,
                    ingredients: parsed.ingredients,
                    instructions: parsed.instructions
                )
                if categorizedRecipes["Uncategorized"] == nil {
                    categorizedRecipes["Uncategorized"] = []
                }
                categorizedRecipes["Uncategorized"]?.append(recipeData)
            }

            if recognizedText.isEmpty {
                print("No Text Found")
            } else {
                print("Recognized Text:\n\(recognizedText)")
                print("=== INGREDIENTS ===")
                parsed.ingredients.forEach { print("- \($0)") }

                print("=== INSTRUCTIONS ===")
                for (i, step) in parsed.instructions.enumerated() {
                    print("\(i + 1). \(step)")
                }
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
    
}

#Preview {
    UploadView(
        selectedImage: .constant(nil),
        categorizedRecipes: .constant([:]),
        isImagePickerPresented: .constant(false)
    )
}

func classifyLines(_ lines: [String], completion: @escaping ([[String: String]]?) -> Void) {
    guard let url = URL(string: "http://localhost:5000/classify") else {
        print("Invalid URL")
        completion(nil)
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")

    let jsonBody = ["lines": lines]
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody, options: [])
    } catch {
        print("Error encoding JSON: \(error)")
        completion(nil)
        return
    }

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Request error: \(error)")
            completion(nil)
            return
        }

        guard let data = data else {
            print("No data received")
            completion(nil)
            return
        }

        do {
            let result = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: String]]
            completion(result)
        } catch {
            print("Failed to decode JSON: \(error)")
            completion(nil)
        }
    }

    task.resume()
}
