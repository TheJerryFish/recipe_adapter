import torch
from transformers import AutoTokenizer, AutoModelForSequenceClassification
import coremltools as ct
import numpy as np

# Wrapper to return only logits output
class LogitsOnlyWrapper(torch.nn.Module):
    def __init__(self, base_model):
        super().__init__()
        self.base = base_model

    def forward(self, input_ids, attention_mask):
        return self.base(input_ids=input_ids, attention_mask=attention_mask).logits

# Load small pretrained model
model_id = "prajjwal1/bert-tiny"
model = LogitsOnlyWrapper(
    AutoModelForSequenceClassification.from_pretrained(model_id, num_labels=2)
)
model.eval()

tokenizer = AutoTokenizer.from_pretrained(model_id)
example = tokenizer("1 cup flour", return_tensors="pt", padding="max_length", truncation=True, max_length=32)

# Trace
traced = torch.jit.trace(model, (example["input_ids"], example["attention_mask"]))

# Convert to Core ML
mlmodel = ct.convert(
    traced,
    convert_to="mlprogram",
    inputs=[
        ct.TensorType(name="input_ids", shape=(1, 32), dtype=np.int32),
        ct.TensorType(name="attention_mask", shape=(1, 32), dtype=np.int32),
    ],
    outputs=[
        ct.TensorType(name="logits", dtype=np.float32)
    ],
    minimum_deployment_target=ct.target.iOS16,
    compute_units=ct.ComputeUnit.CPU_AND_NE,
)
mlmodel.save("TinyRecipeClassifier.mlpackage")