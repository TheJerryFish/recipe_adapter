import Foundation

func extractIngredientsAndInstructions(from text: String) -> (ingredients: [String], instructions: [String]) {
    let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }

    var ingredients: [String] = []
    var instructions: [String] = []

    let ingredientKeywords = ["cup", "tsp", "tbsp", "teaspoon", "tablespoon", "g", "kg", "ml", "oz", "pound", "slice"]
    let instructionStarters = ["step", "1.", "1)", "- ", "* ", "first", "then", "next", "after", "finally"]

    for line in lines {
        let lowercaseLine = line.lowercased()
        if instructionStarters.contains(where: { lowercaseLine.hasPrefix($0) }) || line.split(separator: " ").count > 4 {
            instructions.append(line)
        } else if ingredientKeywords.contains(where: { lowercaseLine.contains($0) }) {
            ingredients.append(line)
        }
    }

    return (ingredients, instructions)
}
