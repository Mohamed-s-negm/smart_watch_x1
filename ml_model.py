#We import the libraries needed
import pandas as pd
import numpy as np
import pickle
import os
from sklearn.model_selection import train_test_split
from sklearn.tree import DecisionTreeClassifier
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, accuracy_score, confusion_matrix

#Create a machine learning class for the model
class ML_Model:

    #define whether we have an already built-in model or just add the dataset path
    def __init__(self, data_path = None, model_file = None):
        self.data_path = data_path
        self.model_file = model_file
        self.X_train = self.X_test = self.y_train = self.y_test = None
        self.model = None
        self.predictions = None
        self.start_evaluate = False

        #We check for the data_path and model_file if exists
        if data_path:
            self.load_split_data(data_path)
        if model_file:
            self.load_model(model_file)

    #We prepare the data to be handled by the model
    def load_split_data(self, data_path):
        # Load the data
        df = pd.read_csv(data_path)
        
        # Select features and target
        feature_columns = [
            'HR_Mean', 'Temp_Mean', 
            'hand_acc_16g_x_Mean', 'hand_acc_16g_y_Mean', 'hand_acc_16g_z_Mean',
            'hand_gyro_x_Mean', 'hand_gyro_y_Mean', 'hand_gyro_z_Mean',
            'hand_magn_x_Mean', 'hand_magn_y_Mean', 'hand_magn_z_Mean',
            'hand_orientation_1_Mean', 'hand_orientation_2_Mean',
            'hand_orientation_3_Mean', 'hand_orientation_4_Mean'
        ]
        
        X = df[feature_columns]
        y = df['Activity_ID_Numerical']
        
        # Split the data
        self.X_train, self.X_test, self.y_train, self.y_test = train_test_split(
            X, y, test_size=0.2, random_state=42
        )

    #Function for the random_forest model
    def random_forest(self):
        print('Training using Random Forest...')
        self.model = RandomForestClassifier(n_estimators=100)
        self.model.fit(self.X_train, self.y_train)

        if not self.model_file:
            self.model_file = "trained_random_forest.pkl"
        self.save_model(self.model_file)
        self.evaluate()

    #Funtion for decision_tree model
    def decision_tree(self):
        print('Training using Decision Tree...')
        self.model = DecisionTreeClassifier()
        self.model.fit(self.X_train, self.y_train)

        if not self.model_file:
            self.model_file = "trained_decision_tree.pkl"
        self.save_model(self.model_file)
        self.evaluate()

    #Function to evaluate the model and it's automatically called after training the model
    def evaluate(self):
        if self.model == None:
            print('No models has been trained.')
            return
        
        self.predictions = self.model.predict(self.X_test)

        print('Accuracy: ', accuracy_score(self.y_test, self.predictions))
        print('Classification Report: ', classification_report(self.y_test, self.predictions))
        print('Confusion Matrix: ', confusion_matrix(self.y_test, self.predictions))

    #Function to make the predictions depending on the input data
    def predict(self, new_data):
        if self.model is None:
            raise Exception("No model loaded. Use load_model() first.")

        return self.model.predict(new_data)
    
    #Function to save the created model and it's called right after creating a model
    def save_model(self, filename):
        if self.model is None:
            raise Exception("No trained model to save.")
        
        with open(filename, 'wb') as f:
            pickle.dump(self.model, f)

    #Function to load an existing model
    def load_model(self, filename):
        if os.path.exists(filename):
            with open(filename, 'rb') as f:
                self.model = pickle.load(f)
                print("[INFO] Loaded existing model.")
        else:
            print("[WARNING] Model file not found.")