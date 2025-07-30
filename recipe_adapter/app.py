from flask import Flask, request, jsonify
import coremltools as ct

app = Flask(__name__)

model = ct.models.MLModel("RecipeTextClassifier.mlpackage")

@app.route("/classify", methods=["POST"])
def classify_lines():
    data = request.get_json()
    lines = data.get("lines", [])

    if not lines or not isinstance(lines, list):
        return jsonify({"error": "Missing or invalid 'lines' array"}), 400

    labeled = []

    for line in lines:
        try:
            prediction = model.predict({"text": line})
            label = prediction["label"]
        except Exception as e:
            label = "error"

        labeled.append({"line": line, "label": label})

    return jsonify(labeled)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)