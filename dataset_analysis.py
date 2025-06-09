import pandas as pd
import numpy as np

# --- Configuration ---
INPUT_FILE_NAME = 'new108.xlsx'
OUTPUT_FILE_NAME = 'pamap2_dynamic_features_single_subject.csv' # New name to reflect single-subject assumption
SAMPLING_RATE = 100 # Hz, typical for PAMAP2 motion sensors. Used for deriving Jerk/Angular Accel.

# Define the *actual* column names from your provided CSV file
# Subject ID is now implicitly 1 for all data
ACTIVITY_ID_COL = 'activity_id'
HEART_RATE_COL = 'heart_rate'
TEMPERATURE_COL = 'hand_temperature'
TIMESTAMP_COL = 'timestamp'

# Actual sensor column names from the provided file
HAND_ACC_COLS = ['hand_acc_16g_x', 'hand_acc_16g_y', 'hand_acc_16g_z']
HAND_GYRO_COLS = ['hand_gyro_x', 'hand_gyro_y', 'hand_gyro_z']
HAND_MAG_COLS = ['hand_magn_x', 'hand_magn_y', 'hand_magn_z']
HAND_ORIENT_COLS = ['hand_orientation_1', 'hand_orientation_2', 'hand_orientation_3', 'hand_orientation_4']

# All columns that are expected to be in the dataset and potentially used
ALL_EXPECTED_COLS = [
    ACTIVITY_ID_COL, TIMESTAMP_COL, HEART_RATE_COL, TEMPERATURE_COL
] + HAND_ACC_COLS + HAND_GYRO_COLS + HAND_MAG_COLS + HAND_ORIENT_COLS

# Columns that MUST NOT have NaNs in a sample for it to be processed (will be dropped at row level)
CRITICAL_SENSOR_COLUMNS_FOR_NAN_CHECK = HAND_ACC_COLS + HAND_GYRO_COLS + HAND_MAG_COLS + HAND_ORIENT_COLS

# --- Feature Extraction Function ---
def extract_features_from_segment(segment_df, segment_index, activity_id, sampling_rate):
    # Subject_ID is fixed to 1 as we assume a single subject
    features = {
        'Subject_ID': 1, # Fixed to 1 as per single-subject assumption
        'Segment_Index': segment_index,
        'Activity_ID_Numerical': activity_id
    }

    # HEART RATE & TEMPERATURE
    if HEART_RATE_COL in segment_df.columns and not segment_df[HEART_RATE_COL].isnull().all():
        features['HR_Mean'] = segment_df[HEART_RATE_COL].mean()
        features['HR_Std'] = segment_df[HEART_RATE_COL].std()
        features['HR_Min'] = segment_df[HEART_RATE_COL].min()
        features['HR_Max'] = segment_df[HEART_RATE_COL].max()
    else:
        features['HR_Mean'] = np.nan
        features['HR_Std'] = np.nan
        features['HR_Min'] = np.nan
        features['HR_Max'] = np.nan

    if TEMPERATURE_COL in segment_df.columns and not segment_df[TEMPERATURE_COL].isnull().all():
        features['Temp_Mean'] = segment_df[TEMPERATURE_COL].mean()
        features['Temp_Std'] = segment_df[TEMPERATURE_COL].std()
    else:
        features['Temp_Mean'] = np.nan
        features['Temp_Std'] = np.nan

    # ACCELERATION
    if all(col in segment_df.columns for col in HAND_ACC_COLS) and len(HAND_ACC_COLS) == 3:
        for col in HAND_ACC_COLS:
            features[f'{col}_Mean'] = segment_df[col].mean()
            features[f'{col}_Std'] = segment_df[col].std()
            features[f'{col}_Min'] = segment_df[col].min()
            features[f'{col}_Max'] = segment_df[col].max()
            features[f'{col}_RMS'] = np.sqrt(np.mean(segment_df[col]**2))

        acc_mag = np.sqrt(segment_df[HAND_ACC_COLS[0]]**2 + segment_df[HAND_ACC_COLS[1]]**2 + segment_df[HAND_ACC_COLS[2]]**2)
        features['Acc_Mag_Mean'] = acc_mag.mean()
        features['Acc_Mag_Std'] = acc_mag.std()
        features['Acc_Mag_Min'] = acc_mag.min()
        features['Acc_Mag_Max'] = acc_mag.max()
        features['Acc_Mag_RMS'] = np.sqrt(np.mean(acc_mag**2))

        for col in HAND_ACC_COLS:
            jerk = segment_df[col].diff() * sampling_rate
            features[f'{col}_Jerk_Mean'] = jerk.mean()
            features[f'{col}_Jerk_Std'] = jerk.std()
    else:
        for col_name in HAND_ACC_COLS:
            features[f'{col_name}_Mean'] = np.nan
            features[f'{col_name}_Std'] = np.nan
            features[f'{col_name}_Min'] = np.nan
            features[f'{col_name}_Max'] = np.nan
            features[f'{col_name}_RMS'] = np.nan
            features[f'{col_name}_Jerk_Mean'] = np.nan
            features[f'{col_name}_Jerk_Std'] = np.nan
        features['Acc_Mag_Mean'] = np.nan
        features['Acc_Mag_Std'] = np.nan
        features['Acc_Mag_Min'] = np.nan
        features['Acc_Mag_Max'] = np.nan
        features['Acc_Mag_RMS'] = np.nan


    # GYROSCOPE
    if all(col in segment_df.columns for col in HAND_GYRO_COLS) and len(HAND_GYRO_COLS) == 3:
        for col in HAND_GYRO_COLS:
            features[f'{col}_Mean'] = segment_df[col].mean()
            features[f'{col}_Std'] = segment_df[col].std()
            features[f'{col}_Min'] = segment_df[col].min()
            features[f'{col}_Max'] = segment_df[col].max()
            features[f'{col}_RMS'] = np.sqrt(np.mean(segment_df[col]**2))

        gyro_mag = np.sqrt(segment_df[HAND_GYRO_COLS[0]]**2 + segment_df[HAND_GYRO_COLS[1]]**2 + segment_df[HAND_GYRO_COLS[2]]**2)
        features['Gyro_Mag_Mean'] = gyro_mag.mean()
        features['Gyro_Mag_Std'] = gyro_mag.std()
        features['Gyro_Mag_Min'] = gyro_mag.min()
        features['Gyro_Mag_Max'] = gyro_mag.max()
        features['Gyro_Mag_RMS'] = np.sqrt(np.mean(gyro_mag**2))
    else:
        for col_name in HAND_GYRO_COLS:
            features[f'{col_name}_Mean'] = np.nan
            features[f'{col_name}_Std'] = np.nan
            features[f'{col_name}_Min'] = np.nan
            features[f'{col_name}_Max'] = np.nan
            features[f'{col_name}_RMS'] = np.nan
        features['Gyro_Mag_Mean'] = np.nan
        features['Gyro_Mag_Std'] = np.nan
        features['Gyro_Mag_Min'] = np.nan
        features['Gyro_Mag_Max'] = np.nan
        features['Gyro_Mag_RMS'] = np.nan


    # MAGNETOMETER
    if all(col in segment_df.columns for col in HAND_MAG_COLS) and len(HAND_MAG_COLS) == 3:
        for col in HAND_MAG_COLS:
            features[f'{col}_Mean'] = segment_df[col].mean()
            features[f'{col}_Std'] = segment_df[col].std()
            features[f'{col}_Min'] = segment_df[col].min()
            features[f'{col}_Max'] = segment_df[col].max()
            features[f'{col}_RMS'] = np.sqrt(np.mean(segment_df[col]**2))

        mag_mag = np.sqrt(segment_df[HAND_MAG_COLS[0]]**2 + segment_df[HAND_MAG_COLS[1]]**2 + segment_df[HAND_MAG_COLS[2]]**2)
        features['Mag_Mag_Mean'] = mag_mag.mean()
        features['Mag_Mag_Std'] = mag_mag.std()
        features['Mag_Mag_Min'] = mag_mag.min()
        features['Mag_Mag_Max'] = mag_mag.max()
        features['Mag_Mag_RMS'] = np.sqrt(np.mean(mag_mag**2))
    else:
        for col_name in HAND_MAG_COLS:
            features[f'{col_name}_Mean'] = np.nan
            features[f'{col_name}_Std'] = np.nan
            features[f'{col_name}_Min'] = np.nan
            features[f'{col_name}_Max'] = np.nan
            features[f'{col_name}_RMS'] = np.nan
        features['Mag_Mag_Mean'] = np.nan
        features['Mag_Mag_Std'] = np.nan
        features['Mag_Mag_Min'] = np.nan
        features['Mag_Mag_Max'] = np.nan
        features['Mag_Mag_RMS'] = np.nan


    # ORIENTATION
    if all(col in segment_df.columns for col in HAND_ORIENT_COLS) and len(HAND_ORIENT_COLS) == 4:
        for col in HAND_ORIENT_COLS:
            features[f'{col}_Mean'] = segment_df[col].mean()
            features[f'{col}_Std'] = segment_df[col].std()
            features[f'{col}_Min'] = segment_df[col].min()
            features[f'{col}_Max'] = segment_df[col].max()
    else:
        for col_name in HAND_ORIENT_COLS:
            features[f'{col_name}_Mean'] = np.nan
            features[f'{col_name}_Std'] = np.nan
            features[f'{col_name}_Min'] = np.nan
            features[f'{col_name}_Max'] = np.nan

    return features

# --- Main Processing Logic ---
def process_data_with_dynamic_indexing(input_file_path, output_file_path, sampling_rate,
                                        activity_col, hr_col, timestamp_col,
                                        critical_sensor_cols_for_nan_check, all_expected_cols):
    print(f"Loading data from {input_file_path}...")
    try:
        # Read Excel file directly since we know it's an Excel file
        df = pd.read_excel(input_file_path)
    except Exception as e:
        print(f"Error loading Excel file: {e}")
        return

    print("Initial DataFrame head:\n", df.head())
    print(f"Initial DataFrame shape: {df.shape}")
    print("Columns available:", df.columns.tolist())

    # Filter for columns that actually exist in the DataFrame
    existing_cols_to_use = [col for col in all_expected_cols if col in df.columns]
    df = df[existing_cols_to_use].copy()

    # Check for essential columns after filtering
    missing_essential_cols = [col for col in [activity_col, hr_col, timestamp_col] if col not in df.columns]
    if missing_essential_cols:
        print(f"Error: Missing essential columns: {missing_essential_cols}. Cannot proceed with processing.")
        return

    # Filter critical sensor columns to only include those present in the actual dataframe
    critical_sensor_cols_filtered_present = [col for col in critical_sensor_cols_for_nan_check if col in df.columns]
    if not critical_sensor_cols_filtered_present:
        print("Warning: No critical sensor columns found for NaN check. Skipping NaN-based row removal.")
        df_cleaned = df.copy()
        nan_removed_count = 0
    else:
        print(f"Initial row count: {len(df)}")
        # Step 1: Ignore (drop) samples with NaNs in critical sensor columns
        nan_mask = df[critical_sensor_cols_filtered_present].isnull().any(axis=1)
        nan_removed_count = nan_mask.sum()
        df_cleaned = df[~nan_mask].copy()
        print(f"Removed {nan_removed_count} rows due to NaNs in critical sensor columns.")
        print(f"DataFrame shape after NaN removal: {df_cleaned.shape}")

    if df_cleaned.empty:
        print("No valid data remaining after NaN removal. Exiting.")
        return

    # Ensure data is sorted for correct index assignment within activity groups
    df_cleaned = df_cleaned.sort_values(by=[activity_col, timestamp_col]).reset_index(drop=True)

    # Step 2: Create dynamic 'Segment_Index' column based on heart_rate presence within each activity_id
    print("Creating dynamic 'Segment_Index' column based on heart_rate presence within each activity...")

    df_cleaned['hr_segment_start'] = df_cleaned.groupby(activity_col)[hr_col].transform(lambda x: x.notna())
    df_cleaned['Segment_Index'] = df_cleaned.groupby(activity_col)['hr_segment_start'].cumsum()

    # Filter out any initial rows in an activity block that don't have a heart rate (i.e., Segment_Index is 0)
    df_cleaned = df_cleaned[df_cleaned['Segment_Index'] > 0].copy()

    if df_cleaned.empty:
        print("No valid data remaining after segment indexing (possibly no HR values found after initial cleaning). Exiting.")
        return

    print(f"Created {df_cleaned['Segment_Index'].nunique()} unique dynamic segments.")
    print(f"DataFrame shape after dynamic indexing: {df_cleaned.shape}")

    processed_features_list = []
    skipped_segments_due_to_size = 0

    # Step 3: Extract features based on new 'Segment_Index' groups
    print("Extracting features from dynamic segments...")
    # Group by activity and the newly created 'Segment_Index'
    for (current_activity_id, segment_idx), segment_df in df_cleaned.groupby([activity_col, 'Segment_Index']):
        # Ensure segment is valid for feature extraction (e.g., at least 2 samples for std dev)
        if len(segment_df) < 2:
            skipped_segments_due_to_size += 1
            continue

        features = extract_features_from_segment(segment_df, segment_idx, current_activity_id, sampling_rate)
        processed_features_list.append(features)

    print(f"Skipped {skipped_segments_due_to_size} segments due to insufficient sample count (<2).")
    print(f"Extracted features for {len(processed_features_list)} dynamic segments.")

    final_df = pd.DataFrame(processed_features_list)

    # The 'Activity_ID_Numerical' column is already numerical as requested.
    # No string mapping is applied to the final output column, as per your instruction.

    print(f"Saving processed features to {output_file_path}...")
    try:
        final_df.to_csv(output_file_path, index=False)
        print("Processed dataset saved successfully.")
        print(f"Head of the new dataset:\n{final_df.head()}")
        print(f"Shape of the new dataset: {final_df.shape}")
    except Exception as e:
        print(f"An error occurred while saving the CSV file: {e}")

    print("\nProcessing complete.")

# --- Execute the script ---
process_data_with_dynamic_indexing(
    input_file_path=INPUT_FILE_NAME,
    output_file_path=OUTPUT_FILE_NAME,
    sampling_rate=SAMPLING_RATE,
    activity_col=ACTIVITY_ID_COL,
    hr_col=HEART_RATE_COL,
    timestamp_col=TIMESTAMP_COL,
    critical_sensor_cols_for_nan_check=CRITICAL_SENSOR_COLUMNS_FOR_NAN_CHECK,
    all_expected_cols=ALL_EXPECTED_COLS
)