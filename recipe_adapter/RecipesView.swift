//
//  RecipesView.swift
//  recipe_adapter
//
//  Created by Jerry on 6/21/25.
//

import SwiftUI

struct RecipesView: View {
    @Binding var categorizedRecipes: [String: [UIImage]]
    @State private var showAddCategory = false
    @State private var showMinusCategory = false
    @State private var newCategoryName = ""

    var body: some View {
        NavigationView {
            List {
                ForEach(self.categorizedRecipes.keys.sorted(), id: \.self) { category in
                    Section(header: Text(category).font(.headline)) {
                        let recipes = self.categorizedRecipes[category] ?? []
                        ForEach(recipes.indices, id: \.self) { index in
                            Image(uiImage: recipes[index])
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                        }
                        .onDelete { indices in
                            self.categorizedRecipes[category]?.remove(atOffsets: indices)
                            if self.categorizedRecipes[category]?.isEmpty == true {
                                self.categorizedRecipes.removeValue(forKey: category)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Recipes")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showMinusCategory = true
                    }) {
                        Image(systemName: "minus")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddCategory = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showMinusCategory) {
                NavigationView {
                    List {
                        ForEach(self.categorizedRecipes.keys.sorted(), id: \.self) { category in
                            HStack {
                                Text(category)
                                Spacer()
                                Button(role: .destructive) {
                                    self.categorizedRecipes.removeValue(forKey: category)
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                        }
                    }
                    .navigationTitle("Delete Category")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") {
                                showMinusCategory = false
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddCategory) {
                VStack(spacing: 20) {
                    Text("Add Category")
                        .font(.headline)
                    TextField("Category name", text: $newCategoryName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    Button("Add") {
                        if !newCategoryName.isEmpty {
                            self.categorizedRecipes[newCategoryName] = []
                            newCategoryName = ""
                            showAddCategory = false
                        }
                    }
                    Button("Cancel") {
                        showAddCategory = false
                    }
                }
                .padding()
            }
        }
    }
}

#Preview {
    RecipesView(categorizedRecipes: .constant([:]))
}
