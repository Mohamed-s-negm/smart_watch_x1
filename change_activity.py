import pandas as pd

# Read the CSV file
print("Reading PAMAP dataset...")
df = pd.read_csv('pamap_dataset.csv')

# Find unique activity IDs and sort them
unique_ids = sorted(df['Activity_ID_Numerical'].dropna().unique())

# Create a mapping: old_id -> new_id (1 to 18)
new_id_map = {old_id: new_id for new_id, old_id in enumerate(unique_ids, start=1)}
print("Activity ID mapping:", new_id_map)

# Apply the mapping
print("\nOriginal activity IDs and their counts:")
print(df['Activity_ID_Numerical'].value_counts().sort_index())
df['Activity_ID_Numerical'] = df['Activity_ID_Numerical'].map(new_id_map)

print("\nNew activity IDs and their counts:")
print(df['Activity_ID_Numerical'].value_counts().sort_index())

# Save the modified dataset
output_file = 'pamap_dataset_mapped_1_to_18.csv'
print(f"\nSaving modified dataset to {output_file}...")
df.to_csv(output_file, index=False)
print("Done!")
