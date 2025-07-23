//
//  DocumentPicker.swift
//  recipe_adapter
//
//  Created by Jerry on 6/28/25.
//

import SwiftUI
import UIKit
import PDFKit

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
    var onDocumentsPicked: ([URL]) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self, onDocumentsPicked: onDocumentsPicked)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .plainText], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        let onDocumentsPicked: ([URL]) -> Void

        init(parent: DocumentPicker, onDocumentsPicked: @escaping ([URL]) -> Void) {
            self.parent = parent
            self.onDocumentsPicked = onDocumentsPicked
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onDocumentsPicked(urls)
            guard let firstURL = urls.first,
                  firstURL.pathExtension.lowercased() == "pdf",
                  let pdf = PDFDocument(url: firstURL),
                  let page = pdf.page(at: 0) else { return }

            let thumbnail = page.thumbnail(of: CGSize(width: 300, height: 300), for: .mediaBox)
            DispatchQueue.main.async {
                self.parent.image = thumbnail
            }
        }
    }
}
