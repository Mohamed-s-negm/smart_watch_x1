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
from dl_pi import DL_ImgClass
from PIL import Image
import io
import torch
from torchvision import transforms
import uuid

app = Flask(__name__)
CORS(app)

# WhatsApp API configuration
WHATSAPP_NUMBER = '+905314316779'
TWILIO_ACCOUNT_SID = 'AC824099da6dc1ee485b0a251111fa3a39'  # Replace with your Twilio SID
TWILIO_AUTH_TOKEN = '63a46350b0fd6f26c366e7988fccf7a7'    # Replace with your Twilio token
TWILIO_WHATSAPP_NUMBER = 'whatsapp:+14155238886'  # Your Twilio WhatsApp number

# Initialize Twilio client
client = Client(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)

# Load the Random Forest model for activity prediction
try:
    model_path = os.path.join('trained_models', 'new_model_rf.pkl')
    with open(model_path, 'rb') as f:
        activity_model = pickle.load(f)
    print(f"Random Forest model loaded successfully from {model_path}")
    print("Model classes:", activity_model.classes_)
except Exception as e:
    print(f"Error loading activity model: {str(e)}")
    activity_model = None

# Initialize the fruit classification model
try:
    print("\n=== Starting Model Initialization ===")
    print("Current working directory:", os.getcwd())
    print("Checking for model file...")
    
    model_path = 'best_model_fruit.pth'
    if os.path.exists(model_path):
        print(f"Found model file at: {os.path.abspath(model_path)}")
        print(f"Model file size: {os.path.getsize(model_path) / (1024*1024):.2f} MB")
    else:
        print(f"Error: Model file not found at {os.path.abspath(model_path)}")
        raise FileNotFoundError(f"Model file not found at {model_path}")
    
    print("\nInitializing model class...")
    # Initialize with CPU device since we're running on a server
    fruit_model = DL_ImgClass(device=torch.device('cpu'), num_classes=6)
    print("Model class initialized successfully")
    
    # Set the class names to match the actual model's output classes
    fruit_model.class_names = [
        'fresh apple', 'rotten apple',
        'fresh banana', 'rotten banana',
        'fresh orange', 'rotten orange'
    ]
    print("Class names set successfully")
    
    print("\nLoading model weights...")
    fruit_model.load_model(model_path)
    print("Model weights loaded successfully")
    print("=== Model Initialization Complete ===\n")
except Exception as e:
    print(f"\nError loading fruit model: {str(e)}")
    import traceback
    print("Full traceback:")
    print(traceback.format_exc())
    fruit_model = None

# Initialize chat history list
chat_history = []

# WhatsApp API endpoints
@app.route('/whatsapp/notifications', methods=['GET'])
def get_notifications():
    try:
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
        
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = f'voice_messages/voice_{timestamp}.m4a'
        os.makedirs('voice_messages', exist_ok=True)
        audio_file.save(filename)
        
        message = client.messages.create(
            from_=TWILIO_WHATSAPP_NUMBER,
            to=f'whatsapp:{WHATSAPP_NUMBER}',
            media_url=[f'https://your-server.com/{filename}']
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

        formatted_message = message
        if reply_to:
            formatted_message = f"Replying to: {reply_to}\n{message}"

        message = client.messages.create(
            from_=TWILIO_WHATSAPP_NUMBER,
            body=formatted_message,
            to=f'whatsapp:{WHATSAPP_NUMBER}'
        )

        chat_history.append({
            'message': message,
            'reply_to': reply_to,
            'time': datetime.now().strftime('%I:%M %p')
        })

        return jsonify({'status': 'success'})
    except Exception as e:
        print(f"Error sending reply: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/whatsapp/chat-history', methods=['GET'])
def get_chat_history():
    return jsonify(chat_history)

# Activity prediction endpoint
@app.route('/predict', methods=['POST'])
def predict_activity():
    try:
        if activity_model is None:
            return jsonify({'error': 'Activity model not loaded'}), 500

        data = request.get_json()
        print("Received data:", data)
        
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

        features_array = np.array(features).reshape(1, -1)
        prediction = activity_model.predict(features_array)[0]
        probabilities = activity_model.predict_proba(features_array)[0]
        prob_dict = {str(i+1): float(prob) for i, prob in enumerate(probabilities)}
        
        return jsonify({
            'predicted_activity': int(prediction),
            'probabilities': prob_dict
        })

    except Exception as e:
        print("Error:", str(e))
        return jsonify({'error': str(e)}), 400

# Fruit classification endpoint
@app.route('/fridge/predict', methods=['POST'])
def predict_fruit():
    if 'image' not in request.files:
        return jsonify({'error': 'No image provided'}), 400

    try:
        if fruit_model is None:
            print("Error: Fruit model is None")
            return jsonify({'error': 'Fruit model not loaded'}), 500

        image_file = request.files['image']
        if not image_file.filename:
            return jsonify({'error': 'No selected file'}), 400
            
        print(f"Received image file: {image_file.filename}")
        
        # Create a unique temporary filename
        temp_filename = f"temp_{uuid.uuid4()}_{image_file.filename}"
        temp_path = os.path.join(os.getcwd(), temp_filename)
        
        print(f"Saving temporary file to: {temp_path}")
        try:
            image_file.save(temp_path)
            if not os.path.exists(temp_path):
                raise Exception("Failed to save temporary file")
                
            # Verify the file is a valid image
            try:
                with Image.open(temp_path) as img:
                    print(f"Image verified. Size: {img.size}, Mode: {img.mode}")
                    # Convert to RGB if needed
                    if img.mode != 'RGB':
                        img = img.convert('RGB')
                        img.save(temp_path)
                        print("Converted image to RGB mode")
            except Exception as e:
                raise Exception(f"Invalid image file: {str(e)}")
            
            print("Calling model.predict...")
            # Get raw model output before class name conversion
            image = Image.open(temp_path)
            transform = transforms.Compose([
                transforms.Resize((224, 224)),
                transforms.ToTensor(),
                transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
            ])
            image_tensor = transform(image).unsqueeze(0)
            
            with torch.no_grad():
                image_tensor = image_tensor.to(fruit_model.device)
                outputs = fruit_model.model(image_tensor)
                probabilities = torch.nn.functional.softmax(outputs, dim=1)[0]
                _, predicted = torch.max(outputs, 1)
                index = predicted.item()
                
                # Log raw probabilities for each class
                print("\nRaw probabilities for each class:")
                for i, prob in enumerate(probabilities):
                    print(f"{fruit_model.class_names[i]}: {prob.item():.4f}")
                print(f"Predicted class index: {index}")
                print(f"Predicted class name: {fruit_model.class_names[index]}")
            
            prediction = fruit_model.predict(temp_path)
            print(f"Final prediction result: {prediction}")
            
            return jsonify({
                'prediction': prediction,
                'confidence': 1.0  # The current implementation doesn't return confidence
            })
            
        finally:
            # Always clean up the temporary file
            try:
                if os.path.exists(temp_path):
                    os.remove(temp_path)
                    print("Temporary file cleaned up")
            except Exception as e:
                print(f"Warning: Failed to clean up temporary file: {str(e)}")
        
    except Exception as e:
        print(f"Error in fruit prediction: {str(e)}")
        import traceback
        print("Full traceback:")
        print(traceback.format_exc())
        return jsonify({'error': str(e)}), 500

# Test endpoint to verify model loading
@app.route('/test-model', methods=['GET'])
def test_model():
    if fruit_model is None:
        return jsonify({'status': 'error', 'message': 'Model not loaded'}), 500
    return jsonify({'status': 'success', 'message': 'Model loaded successfully'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True) 