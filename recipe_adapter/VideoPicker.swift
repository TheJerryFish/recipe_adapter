//
//  VideoPicker.swift
//  recipe_adapter
//
//  Created by Jerry on 6/28/25.
//

import SwiftUI
import UIKit

struct VideoPicker: UIViewControllerRepresentable {
    var onVideoPicked: (URL) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onVideoPicked: onVideoPicked)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.movie], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onVideoPicked: (URL) -> Void

        init(onVideoPicked: @escaping (URL) -> Void) {
            self.onVideoPicked = onVideoPicked
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                onVideoPicked(url)
            }
        }
    }
}
