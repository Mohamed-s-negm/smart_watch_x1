from ml_model import ML_Model
import os

# Define the model file path
model_file = 'smart_watch_x1/trainted_models/Input the trained file you want to use.'

# Check if the model file exists
if not os.path.exists(model_file):
    print(f"Error: Model file not found at {model_file}")
    print("Please make sure the model file exists and the path is correct.")
else:
    # Initialize the model
    trainer = ML_Model(model_file=model_file)
    
    # Define new data for prediction
    new = [[60, 36.42, 97, 0.6]]
    
    # Make prediction
    try:
        result = trainer.predict(new)
        print(f"Prediction result: {result}")
    except Exception as e:
        print(f"Error making prediction: {str(e)}")