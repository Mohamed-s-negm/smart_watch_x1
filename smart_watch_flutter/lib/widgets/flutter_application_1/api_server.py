from flask import Flask, request, jsonify
from flask_cors import CORS
import pickle
import numpy as np
import pandas as pd
from burn_cal import CaloriesBurnt
import os
from datetime import datetime
import requests
from twilio.rest import Client

app = Flask(__name__)
CORS(app)

# WhatsApp API configuration
WHATSAPP_NUMBER = '+905314316779'
TWILIO_ACCOUNT_SID = 'AC824099da6dc1ee485b0a251111fa3a39'  # Replace with your Twilio SID
TWILIO_AUTH_TOKEN = '63a46350b0fd6f26c366e7988fccf7a7'    # Replace with your Twilio token
TWILIO_WHATSAPP_NUMBER = 'whatsapp:+14155238886'  # Your Twilio WhatsApp number

# Initialize Twilio client
client = Client(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)

# Load the Random Forest model
try:
    model_path = os.path.join('trained_models', 'new_model_rf.pkl')
    with open(model_path, 'rb') as f:
        model = pickle.load(f)
    print(f"Random Forest model loaded successfully from {model_path}")
    print("Model classes:", model.classes_)
except Exception as e:
    print(f"Error loading model: {str(e)}")
    model = None

# WhatsApp API endpoints
@app.route('/whatsapp/notifications', methods=['GET'])
def get_notifications():
    try:
        # Get messages from Twilio
        messages = client.messages.list(
            to=f'whatsapp:{WHATSAPP_NUMBER}',
            limit=10
        )
        
        notifications = []
        for message in messages:
            notifications.append({
                'title': 'New Message',
                'message': message.body,
                'time': message.date_created.strftime('%I:%M %p')
            })
        
        return jsonify(notifications)
    except Exception as e:
        print(f"Error getting notifications: {str(e)}")
        return jsonify([])

@app.route('/whatsapp/chats', methods=['GET'])
def get_chats():
    try:
        # Get conversations from Twilio
        conversations = client.conversations.conversations.list(limit=10)
        
        chats = []
        for conv in conversations:
            messages = client.messages.list(
                conversation_sid=conv.sid,
                limit=1
            )
            
            if messages:
                last_message = messages[0]
                chats.append({
                    'name': conv.friendly_name or 'Unknown',
                    'lastMessage': last_message.body,
                    'time': last_message.date_created.strftime('%I:%M %p')
                })
        
        return jsonify(chats)
    except Exception as e:
        print(f"Error getting chats: {str(e)}")
        return jsonify([])

@app.route('/whatsapp/send-voice', methods=['POST'])
def send_voice_message():
    try:
        if 'audio' not in request.files:
            return jsonify({'error': 'No audio file provided'}), 400
        
        audio_file = request.files['audio']
        if audio_file.filename == '':
            return jsonify({'error': 'No selected file'}), 400
        
        # Save the audio file
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = f'voice_messages/voice_{timestamp}.m4a'
        os.makedirs('voice_messages', exist_ok=True)
        audio_file.save(filename)
        
        # Send voice message via Twilio
        message = client.messages.create(
            from_=TWILIO_WHATSAPP_NUMBER,
            to=f'whatsapp:{WHATSAPP_NUMBER}',
            media_url=[f'https://your-server.com/{filename}']  # Replace with your server URL
        )
        
        return jsonify({'message': 'Voice message sent successfully'})
    except Exception as e:
        print(f"Error sending voice message: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/whatsapp/reply', methods=['POST'])
def send_whatsapp_reply():
    try:
        data = request.get_json()
        message = data.get('message')
        reply_to = data.get('reply_to')

        if not message:
            return jsonify({'error': 'Message is required'}), 400

        # Format the message with reply context if needed
        formatted_message = message
        if reply_to:
            formatted_message = f"Replying to: {reply_to}\n{message}"

        # Send message using Twilio
        message = client.messages.create(
            from_=TWILIO_WHATSAPP_NUMBER,
            body=formatted_message,
            to=f'whatsapp:{WHATSAPP_NUMBER}'
        )

        # Store the message in chat history
        chat_history.append({
            'message': message,
            'reply_to': reply_to,
            'time': datetime.now().strftime('%I:%M %p')
        })

        return jsonify({'status': 'success'})
    except Exception as e:
        print(f"Error sending reply: {str(e)}")
        return jsonify({'error': str(e)}), 500

# Initialize chat history list
chat_history = []

@app.route('/whatsapp/chats', methods=['GET'])
def get_chat_history():
    return jsonify(chat_history)

# Existing fitness tracking endpoints
@app.route('/predict', methods=['POST'])
def predict():
    try:
        if model is None:
            return jsonify({'error': 'Model not loaded'}), 500

        data = request.get_json()
        print("Received data:", data)
        
        # Extract features in the correct order
        features = [
            data['HR_Mean'],
            data['Temp_Mean'],
            data['hand_acc_16g_x_Mean'],
            data['hand_acc_16g_y_Mean'],
            data['hand_acc_16g_z_Mean'],
            data['hand_gyro_x_Mean'],
            data['hand_gyro_y_Mean'],
            data['hand_gyro_z_Mean'],
            data['hand_magn_x_Mean'],
            data['hand_magn_y_Mean'],
            data['hand_magn_z_Mean'],
            data['hand_orientation_1_Mean'],
            data['hand_orientation_2_Mean'],
            data['hand_orientation_3_Mean'],
            data['hand_orientation_4_Mean']
        ]

        # Convert to numpy array and reshape for prediction
        features_array = np.array(features).reshape(1, -1)
        
        # Get prediction
        prediction = model.predict(features_array)[0]
        
        # Get probabilities for all classes
        probabilities = model.predict_proba(features_array)[0]
        
        # Convert probabilities to a dictionary
        prob_dict = {str(i+1): float(prob) for i, prob in enumerate(probabilities)}
        
        return jsonify({
            'predicted_activity': int(prediction),
            'probabilities': prob_dict
        })

    except Exception as e:
        print("Error:", str(e))
        return jsonify({'error': str(e)}), 400

if __name__ == '__main__':
    app.run(debug=True, port=5000) 