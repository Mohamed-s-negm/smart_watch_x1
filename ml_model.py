import pandas as pd
import numpy as np
import pickle
import os
from sklearn.model_selection import train_test_split
from sklearn.tree import DecisionTreeClassifier
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, accuracy_score, confusion_matrix

class ML_Model:
    def __init__(self, data_path = None, model_file = None):
        self.data_path = data_path
        self.model_file = model_file
        self.X_train = self.X_test = self.y_train = self.y_test = None
        self.model = None
        self.predictions = None
        self.start_evaluate = False

        if data_path:
            self.load_split_data(data_path)
        if model_file:
            self.load_model(model_file)

    def load_split_data(self, path):
        df = pd.read_csv(path)
        X = df.drop(columns='State')
        y = df['State']
        self.X_train, self.X_test, self.y_train, self.y_test = train_test_split(
            X, y, test_size=0.3, random_state=101
        )

    def random_forest(self):
        print('Training using Random Forest...')
        self.model = RandomForestClassifier(n_estimators=100)
        self.model.fit(self.X_train, self.y_train)

        if not self.model_file:
            self.model_file = "trained_random_forest.pkl"
        self.save_model(self.model_file)
        self.evaluate()

    def decision_tree(self):
        print('Training using Decision Tree...')
        self.model = DecisionTreeClassifier()
        self.model.fit(self.X_train, self.y_train)

        if not self.model_file:
            self.model_file = "trained_decision_tree.pkl"
        self.save_model(self.model_file)
        self.evaluate()

    def evaluate(self):
        if self.model == None:
            print('No models has been trained.')
            return
        
        self.predictions = self.model.predict(self.X_test)

        print('Accuracy: ', accuracy_score(self.y_test, self.predictions))
        print('Classification Report: ', classification_report(self.y_test, self.predictions))
        print('Confusion Matrix: ', confusion_matrix(self.y_test, self.predictions))

    def predict(self, new_data):
        if self.model is None:
            raise Exception("No model loaded. Use load_model() first.")

        return self.model.predict(new_data)
    
    def save_model(self, filename):
        if self.model is None:
            raise Exception("No trained model to save.")
        
        with open(filename, 'wb') as f:
            pickle.dump(self.model, f)

    def load_model(self, filename):
        if os.path.exists(filename):
            with open(filename, 'rb') as f:
                self.model = pickle.load(f)
                print("[INFO] Loaded existing model.")
        else:
            print("[WARNING] Model file not found.")