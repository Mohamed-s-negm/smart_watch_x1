from flask import Flask, request, jsonify
from dl_pi import DL_ImgClass
from PIL import Image
import io
import os
import torch
import numpy as np

app = Flask(__name__)

# Initialize the model
model = DL_ImgClass(num_classes=6)  # Adjust num_classes based on your dataset
model.load_model('best_model_fruit.pth')
model.eval()  # Set to evaluation mode

@app.route('/fridge/predict', methods=['POST'])
def predict():
    if 'image' not in request.files:
        return jsonify({'error': 'No image provided'}), 400

    try:
        # Get the image file
        image_file = request.files['image']
        
        # Read and process the image
        image = Image.open(image_file)
        
        # Convert to RGB if needed
        if image.mode != 'RGB':
            image = image.convert('RGB')
        
        # Resize to match model's expected input size
        image = image.resize((224, 224))
        
        # Convert to tensor and normalize
        image_tensor = torch.from_numpy(np.array(image)).float()
        image_tensor = image_tensor.permute(2, 0, 1)  # Change from HWC to CHW
        image_tensor = image_tensor / 255.0  # Normalize to [0, 1]
        
        # Add batch dimension
        image_tensor = image_tensor.unsqueeze(0)
        
        # Make prediction
        with torch.no_grad():
            output = model(image_tensor)
            probabilities = torch.softmax(output, dim=1)
            confidence, prediction = torch.max(probabilities, 1)
            
            # Get class names (you should define these based on your model)
            class_names = ['apple', 'banana', 'orange', 'strawberry', 'grape', 'watermelon']
            predicted_class = class_names[prediction.item()]
            confidence_value = confidence.item()
        
        return jsonify({
            'prediction': predicted_class,
            'confidence': confidence_value
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True) 