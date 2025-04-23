from ml_model import ML_Model
from burn_cal import CaloriesBurnt
import os

# Define the model file path
model_file = 'smart_watch_x1/trainted_models/Input the trained file you want to use.'

#user inputs
gender = input("Input you gender...(male/female)")
age = input("Input your age...")
weight = input("Input your weight...")
heartbr = input("Input the heartbeat rate...")
oxygen = input("Input the oxygen level...")
temp = input("Input the temperature...")
loc = input("Input the change in position...")

# Check if the model file exists
if not os.path.exists(model_file):
    print(f"Error: Model file not found at {model_file}")
    print("Please make sure the model file exists and the path is correct.")
else:
    # Initialize the model
    trainer = ML_Model(model_file=model_file)
    calories = CaloriesBurnt(gender, weight, age)
    
    # Define new data for prediction
    new = [[heartbr, temp, oxygen, loc]]
    
    # Make prediction
    try:
        result = trainer.predict(new)
        print(f"Prediction result: {result}")
        calories.cal_count(heartbr)
    except Exception as e:
        print(f"Error making prediction: {str(e)}")