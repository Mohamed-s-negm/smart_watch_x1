import pandas as pd
import argparse
import os
from pathlib import Path

# PAMAP2 dataset column names
PAMAP2_COLUMNS = [
    'timestamp', 'activity_id', 'heart_rate',
    # IMU hand
    'hand_temperature', 'hand_acc_16g_x', 'hand_acc_16g_y', 'hand_acc_16g_z',
    'hand_acc_6g_x', 'hand_acc_6g_y', 'hand_acc_6g_z',
    'hand_gyro_x', 'hand_gyro_y', 'hand_gyro_z',
    'hand_magn_x', 'hand_magn_y', 'hand_magn_z',
    'hand_orientation_1', 'hand_orientation_2', 'hand_orientation_3', 'hand_orientation_4',
    # IMU chest
    'chest_temperature', 'chest_acc_16g_x', 'chest_acc_16g_y', 'chest_acc_16g_z',
    'chest_acc_6g_x', 'chest_acc_6g_y', 'chest_acc_6g_z',
    'chest_gyro_x', 'chest_gyro_y', 'chest_gyro_z',
    'chest_magn_x', 'chest_magn_y', 'chest_magn_z',
    'chest_orientation_1', 'chest_orientation_2', 'chest_orientation_3', 'chest_orientation_4',
    # IMU ankle
    'ankle_temperature', 'ankle_acc_16g_x', 'ankle_acc_16g_y', 'ankle_acc_16g_z',
    'ankle_acc_6g_x', 'ankle_acc_6g_y', 'ankle_acc_6g_z',
    'ankle_gyro_x', 'ankle_gyro_y', 'ankle_gyro_z',
    'ankle_magn_x', 'ankle_magn_y', 'ankle_magn_z',
    'ankle_orientation_1', 'ankle_orientation_2', 'ankle_orientation_3', 'ankle_orientation_4'
]

def convert_dat_to_csv(input_file, output_file=None, delimiter=None, is_pamap2=False):
    """
    Convert a .dat file to .csv format
    
    Args:
        input_file (str): Path to the input .dat file
        output_file (str, optional): Path to the output .csv file. If not provided, will use same name as input
        delimiter (str, optional): Delimiter used in the .dat file. If not provided, will try common delimiters
        is_pamap2 (bool): Whether this is a PAMAP2 dataset file
    """
    try:
        # If output file is not specified, create one with same name
        if output_file is None:
            output_file = str(Path(input_file).with_suffix('.csv'))
        
        # For PAMAP2 dataset, we know it's space-separated
        if is_pamap2:
            df = pd.read_csv(input_file, delimiter=' ', header=None, names=PAMAP2_COLUMNS)
        else:
            # Try to read the file with different delimiters if not specified
            if delimiter is None:
                delimiters = [',', '\t', ';', '|', ' ']
                for d in delimiters:
                    try:
                        df = pd.read_csv(input_file, delimiter=d)
                        if len(df.columns) > 1:  # If we found multiple columns, this delimiter worked
                            delimiter = d
                            break
                    except:
                        continue
                if delimiter is None:
                    raise ValueError("Could not determine the delimiter. Please specify it manually.")
            else:
                df = pd.read_csv(input_file, delimiter=delimiter)
        
        # Save to CSV
        df.to_csv(output_file, index=False)
        print(f"Successfully converted {input_file} to {output_file}")
        
    except Exception as e:
        print(f"Error converting file: {str(e)}")

def convert_directory(input_dir, is_pamap2=False):
    """
    Convert all .dat files in a directory to .csv format
    """
    input_path = Path(input_dir)
    if not input_path.exists():
        print(f"Error: Directory '{input_dir}' does not exist")
        return
    
    # Convert all .dat files in the directory
    for dat_file in input_path.glob('*.dat'):
        output_file = dat_file.with_suffix('.csv')
        convert_dat_to_csv(str(dat_file), str(output_file), is_pamap2=is_pamap2)

def main():
    parser = argparse.ArgumentParser(description='Convert .dat files to .csv format')
    parser.add_argument('input', help='Path to the input .dat file or directory')
    parser.add_argument('-o', '--output', help='Path to the output .csv file (optional)')
    parser.add_argument('-d', '--delimiter', help='Delimiter used in the .dat file (optional)')
    parser.add_argument('--pamap2', action='store_true', help='Specify if this is a PAMAP2 dataset file')
    
    args = parser.parse_args()
    
    # Check if input is a directory
    if os.path.isdir(args.input):
        convert_directory(args.input, args.pamap2)
    else:
        # Check if input file exists
        if not os.path.exists(args.input):
            print(f"Error: Input file '{args.input}' does not exist")
            return
        
        # Check if input file has .dat extension
        if not args.input.lower().endswith('.dat'):
            print("Warning: Input file does not have .dat extension")
        
        convert_dat_to_csv(args.input, args.output, args.delimiter, args.pamap2)

if __name__ == "__main__":
    main() 