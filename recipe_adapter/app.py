from flask import Flask, request, jsonify
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM, pipeline

app = Flask(__name__)

# Load the T5 model and tokenizer
model_name = "google/flan-t5-base"
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForSeq2SeqLM.from_pretrained(model_name)

classifier = pipeline("text2text-generation", model=model, tokenizer=tokenizer)

@app.route("/classify", methods=["POST"])
def classify_lines():
    data = request.get_json()
    lines = data.get("lines", [])

    if not lines or not isinstance(lines, list):
        return jsonify({"error": "Missing or invalid 'lines' array"}), 400

    labeled = []
    valid_labels = {"ingredient", "instruction", "other"}

    for line in lines:
        prompt = (
            "Classify this line as either 'ingredient', 'instruction', or 'other'.\n"
            f"Line: {line}\n"
            "Label:"
        )
        try:
            result = classifier(prompt, max_new_tokens=5)[0]["generated_text"]
            label = result.strip().lower()
            if label not in valid_labels:
                label = "unknown"
        except Exception as e:
            label = "error"

        labeled.append({"line": line, "label": label})

    return jsonify(labeled)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)