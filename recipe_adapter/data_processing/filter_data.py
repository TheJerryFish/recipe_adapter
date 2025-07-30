import pandas as pd

# Load the CSV
df = pd.read_csv('parsed_data.csv')

# Randomly shuffle and split (80-20)
train_df = df.sample(frac=0.8, random_state=42)  # 80% for training
test_df = df.drop(train_df.index)                # Remaining 20% for testing

# Save to new CSV files
train_df.to_csv('parsed_data_train.csv', index=False)
test_df.to_csv('parsed_data_test.csv', index=False)

print("Split completed:")
print(f"Train set: {len(train_df)} rows")
print(f"Test set: {len(test_df)} rows")