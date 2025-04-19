import pandas as pd
import numpy as np



# Load your dataset
df = pd.read_csv('smart_watch_x1/csv_files/new_dataset.csv')

# Create group labels (each group has 10 samples)
df['groups'] = np.repeat(np.arange(len(df) // 10), 10)
# We have 996 number of groups in the dataset.

# We get the average values of each group
averages_heart = df.groupby('groups')['HeartRate_bpm'].mean().reset_index()
averages_temp = df.groupby('groups')['Temperature_C'].mean().reset_index()
averages_ox = df.groupby('groups')['SpO2_percent'].mean().reset_index()
averages_motion = df.groupby('groups')['MotionLevel'].mean().reset_index()

# We get the state of each group
state = df['State'][::10].reset_index(drop=True)

# We make a new DataFrame using the average values.
new_df = pd.DataFrame({
    'bpm': averages_heart['HeartRate_bpm'],
    'temp': averages_temp['Temperature_C'],
    'Oxyg': averages_ox['SpO2_percent'],
    'motion': averages_motion['MotionLevel'],
    'State': state
})

# We store the new DataFrame into a csv file 
new_df.to_csv('ml_dataset.csv', index=False)