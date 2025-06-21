//
//  UploadView.swift
//  recipe_adapter
//
//  Created by Jerry on 6/21/25.
//

import SwiftUI
import Vision

struct UploadView: View {
    @Binding var selectedImage: UIImage?
    @Binding var categorizedRecipes: [String: [UIImage]]
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
                        if categorizedRecipes["Uncategorized"] == nil {
                            categorizedRecipes["Uncategorized"] = []
                        }
                        categorizedRecipes["Uncategorized"]?.append(image)
                        recognizeText(from: image)
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
