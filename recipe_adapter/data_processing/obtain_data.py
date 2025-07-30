import pandas as pd
import ast

# 1. Load your CSV
df = pd.read_csv("data.csv")  # adjust name

rows = []

for _, row in df.iterrows():
    # --- TITLE ---
    title = str(row['Title']).strip()
    if title:
        rows.append([title, "Title"])
    
    # --- INGREDIENTS ---
    raw_ingredients = str(row['Ingredients'])
    try:
        ingredients_list = ast.literal_eval(raw_ingredients)
        if isinstance(ingredients_list, list):
            for ing in ingredients_list:
                ing = str(ing).strip()
                if ing:
                    rows.append([ing, "Ingredient"])
        else:
            # fallback: split by comma
            for ing in raw_ingredients.split(','):
                ing = ing.strip(" []'\"")
                if ing:
                    rows.append([ing, "Ingredient"])
    except:
        # fallback for malformed entries
        for ing in raw_ingredients.split(','):
            ing = ing.strip(" []'\"")
            if ing:
                rows.append([ing, "Ingredient"])

    # --- INSTRUCTIONS ---
    raw_instructions = str(row['Instructions']).replace("\n", ".")
    for sentence in raw_instructions.split('.'):
        sentence = sentence.strip()
        if sentence:
            rows.append([sentence, "Instruction"])

# 2. Save CSV
output_df = pd.DataFrame(rows, columns=["text", "label"])
output_df.to_csv("create_ml_text_dataset.csv", index=False)
print(f"Done! {len(output_df)} rows created for Create ML.")