//
//  ContentView.swift
//  recipe_adapter
//
//  Created by Jerry on 6/20/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedImage: UIImage? = nil
    @State private var isImagePickerPresented = false
    @State private var categorizedRecipes: [String: [UIImage]] = [:]

    var body: some View {
        TabView {
            UploadView(selectedImage: $selectedImage, categorizedRecipes: $categorizedRecipes, isImagePickerPresented: $isImagePickerPresented)
                .tabItem {
                    Label("Upload", systemImage: "square.and.arrow.up")
                }

            RecipesView(categorizedRecipes: $categorizedRecipes)
                .tabItem {
                    Label("Recipes", systemImage: "book")
                }
        }
    }
}

#Preview {
    ContentView()
}
