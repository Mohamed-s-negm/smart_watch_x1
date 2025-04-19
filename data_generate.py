import pandas as pd
import numpy as np



# Load your dataset
df = pd.read_csv('smart_watch_x1/csv_files/dataset_v1.csv')

# Create group labels (each group has 10 samples)
df['group'] = np.repeat(np.arange(len(df) // 10), 10)

# Shuffle the groups while keeping samples within groups together
# First, get unique groups and shuffle them
unique_groups = np.arange(len(df) // 10)
np.random.shuffle(unique_groups)

# Create a mapping from old group numbers to new shuffled order
group_mapping = {old: new for new, old in enumerate(unique_groups)}

# Apply the mapping to create new group numbers
df['new_group'] = df['group'].map(group_mapping)

# Sort by new group numbers to keep samples within groups together
shuffled_df = df.sort_values('new_group').drop(columns=['group', 'new_group','index'])

# Save the shuffled dataset
shuffled_df.to_csv('new_dataset.csv', index=False)

