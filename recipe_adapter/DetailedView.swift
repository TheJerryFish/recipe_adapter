//
//  DetailedView.swift
//  recipe_adapter
//
//  Created by Jerry on 6/23/25.
//


import SwiftUI

struct DetailedView: View {
    let image: UIImage
    let ingredients: [String]
    let instructions: [String]

    var body: some View {
        ScrollView {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(height: 300)
                .padding()

            VStack(alignment: .leading, spacing: 10) {
                Text("Ingredients")
                    .font(.headline)

                ForEach(ingredients, id: \.self) { ingredient in
                    Text("• \(ingredient)")
                }

                Text("Instructions")
                    .font(.headline)
                    .padding(.top)

                ForEach(instructions.indices, id: \.self) { index in
                    Text("\(index + 1). \(instructions[index])")
                }
            }
            .padding()
        }
        .navigationTitle("Recipe Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}