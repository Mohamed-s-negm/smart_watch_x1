import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.model_selection import train_test_split
from sklearn.tree import DecisionTreeClassifier
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, accuracy_score, confusion_matrix

# We load our new ml_dataset
df = pd.read_csv('smart_watch_x1/csv_files/ml_dataset.csv')

# We get the info of our Dataset
print(df.info())
sns.pairplot(df, hue='State')

# We split the data for training
X = df.drop(columns='State')
y = df['State']

# We assign 70% of the data to be for training and 30% for testing.
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3, random_state=101)

# We use DecisionTreeClassifier model
dt = DecisionTreeClassifier()

dt.fit(X_train, y_train)

dt_predict = dt.predict(X_test)

print('Accuracy: ', accuracy_score(y_test, dt_predict))
print('Classification Report: ', classification_report(y_test, dt_predict))
print('Confusion Matrix: ', confusion_matrix(y_test, dt_predict))

#-----------------------------------------------------------------

#We use RandomForest model
rd = RandomForestClassifier(n_estimators=100)

rd.fit(X_train, y_train)

rd_predict = rd.predict(X_test)

print('Accuracy: ', accuracy_score(y_test, rd_predict))
print('Classification Report: ', classification_report(y_test, rd_predict))
print('Confusion Matrix: ', confusion_matrix(y_test, rd_predict))