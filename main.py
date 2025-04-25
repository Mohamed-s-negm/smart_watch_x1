import streamlit as st
from datetime import datetime
from ml_model import ML_Model
from burn_cal import CaloriesBurnt
import os


#Get the time
current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
# Define the model file path and call the ML model
model_file = 'trained_models/trained_random_forest.pkl'

if not os.path.exists(model_file):
    print(f"Error: Model file not found at {model_file}")
    print("Please make sure the model file exists and the path is correct.")

else:

    #Activate the ML model
    trainer = ML_Model(model_file=model_file)

    #UI interface using streamlit


    #show the time
    st.write(f"{current_time}")

    #user inputs
    st.subheader("User Information")
    gender = st.selectbox("Gender",["male","female"])
    age = st.number_input("Input your age")
    weight = st.number_input("Input your weight")
    heartbr = st.number_input("Input the heartbeat rate")
    oxygen = st.slider("Input the oxygen level % ", min_value=0, max_value=100)
    temp = st.number_input("Input the temperature")
    loc = st.select_slider("Input the change in position", options=[1, 2, 3, 4, 5])

    submit_button = st.button(label="Start")

    #if the submit_button is clicked then start
    if submit_button:

        #Calculate the calories
        calories = CaloriesBurnt(gender, weight, age)
            
        # Define new data for prediction
        new = [[heartbr, temp, oxygen, loc]]
            
        # Make prediction
        try:
            user_state = trainer.predict(new)
            st.write(f"Prediction result: {user_state}")
            user_cals = calories.cal_count(heartbr)
            st.write(f"The user burns {user_cals} calories per minute.")

            #check for danger situations
            if user_state in ['Stress/Panic', 'Hypoxia', 'Seizure', 'Fainting', 'Unconscious']:
                st.warning("Danger state is detected!")

        except Exception as e:
            st.write(f"Error making prediction: {str(e)}")