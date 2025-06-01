import json
import paho.mqtt.client as mqtt
import tkinter as tk
from tkinter import ttk
import threading
import time
import ssl

# MQTT Configuration
MQTT_BROKER = "192.168.1.8"  # Your private MQTT broker
MQTT_PORT = 8883  # Secure MQTT port
MQTT_TOPIC = "smart_watch_x1/sensors"
MQTT_USERNAME = "smart_watch_pc"  # Strong username
MQTT_PASSWORD = "P@ssw0rd!2024#Secure"  # Strong password
MQTT_CA_CERT = "/path/to/ca.crt"  # Path to CA certificate
MQTT_CLIENT_CERT = "/path/to/client.crt"  # Path to client certificate
MQTT_CLIENT_KEY = "/path/to/client.key"  # Path to client key

class SensorDisplay:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("Smart Watch Sensor Data")
        self.root.geometry("400x300")
        
        # Create labels
        self.create_labels()
        
        # Initialize MQTT client with unique client ID
        self.client = mqtt.Client(client_id=f"smart_watch_pc_{int(time.time())}")
        self.client.on_connect = self.on_connect
        self.client.on_message = self.on_message
        
        # Set username and password
        self.client.username_pw_set(MQTT_USERNAME, MQTT_PASSWORD)
        
        # Set TLS/SSL
        self.client.tls_set(
            ca_certs=MQTT_CA_CERT,
            certfile=MQTT_CLIENT_CERT,
            keyfile=MQTT_CLIENT_KEY,
            cert_reqs=ssl.CERT_REQUIRED,
            tls_version=ssl.PROTOCOL_TLS,
            ciphers=None
        )
        
        # Set TLS options
        self.client.tls_insecure_set(False)  # Don't allow insecure connections
        
        # Start MQTT connection in a separate thread
        self.mqtt_thread = threading.Thread(target=self.connect_mqtt)
        self.mqtt_thread.daemon = True
        self.mqtt_thread.start()
        
    def create_labels(self):
        # Heart Rate
        ttk.Label(self.root, text="Heart Rate:").pack(pady=5)
        self.heart_rate_label = ttk.Label(self.root, text="-- BPM")
        self.heart_rate_label.pack()
        
        # Temperature
        ttk.Label(self.root, text="Temperature:").pack(pady=5)
        self.temp_label = ttk.Label(self.root, text="-- °C")
        self.temp_label.pack()
        
        # Acceleration
        ttk.Label(self.root, text="Acceleration:").pack(pady=5)
        self.accel_frame = ttk.Frame(self.root)
        self.accel_frame.pack()
        
        self.accel_x_label = ttk.Label(self.accel_frame, text="X: -- m/s²")
        self.accel_x_label.pack(side=tk.LEFT, padx=5)
        
        self.accel_y_label = ttk.Label(self.accel_frame, text="Y: -- m/s²")
        self.accel_y_label.pack(side=tk.LEFT, padx=5)
        
        self.accel_z_label = ttk.Label(self.accel_frame, text="Z: -- m/s²")
        self.accel_z_label.pack(side=tk.LEFT, padx=5)
    
    def on_connect(self, client, userdata, flags, rc):
        print(f"Connected to MQTT broker with result code: {rc}")
        client.subscribe(MQTT_TOPIC)
    
    def on_message(self, client, userdata, msg):
        try:
            data = json.loads(msg.payload.decode())
            
            # Update labels
            self.heart_rate_label.config(text=f"{data['heart_rate']} BPM")
            self.temp_label.config(text=f"{data['temperature']} °C")
            self.accel_x_label.config(text=f"X: {data['acceleration']['x']} m/s²")
            self.accel_y_label.config(text=f"Y: {data['acceleration']['y']} m/s²")
            self.accel_z_label.config(text=f"Z: {data['acceleration']['z']} m/s²")
            
        except Exception as e:
            print(f"Error processing message: {e}")
    
    def connect_mqtt(self):
        self.client.connect(MQTT_BROKER, MQTT_PORT, 60)
        self.client.loop_forever()
    
    def run(self):
        self.root.mainloop()

if __name__ == "__main__":
    app = SensorDisplay()
    app.run() 