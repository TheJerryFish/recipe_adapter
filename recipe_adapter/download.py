from transformers import MT5ForConditionalGeneration, MT5Tokenizer

model_name = "google/mt5-small"

# Load model and tokenizer
model = MT5ForConditionalGeneration.from_pretrained(model_name)
tokenizer = MT5Tokenizer.from_pretrained(model_name)

# Save locally
model.save_pretrained("mt5_model")
tokenizer.save_pretrained("mt5_tokenizer")