import time
import json
import paho.mqtt.client as mqtt
from sensor_reader import max30102, mcp9808, mpu6050
import ssl

# MQTT Configuration
MQTT_BROKER = "192.168.1.8"  # Your private MQTT broker
MQTT_PORT = 8883  # Secure MQTT port
MQTT_TOPIC = "smart_watch_x1/sensors"
MQTT_USERNAME = "smart_watch_pi"  # Strong username
MQTT_PASSWORD = "P@ssw0rd!2024#Secure"  # Strong password
MQTT_CA_CERT = "/path/to/ca.crt"  # Path to CA certificate
MQTT_CLIENT_CERT = "/path/to/client.crt"  # Path to client certificate
MQTT_CLIENT_KEY = "/path/to/client.key"  # Path to client key

# Initialize MQTT client with unique client ID
client = mqtt.Client(client_id=f"smart_watch_pi_{int(time.time())}")

def on_connect(client, userdata, flags, rc):
    print(f"Connected to MQTT broker with result code: {rc}")

def connect_mqtt():
    # Set username and password
    client.username_pw_set(MQTT_USERNAME, MQTT_PASSWORD)
    
    # Set TLS/SSL
    client.tls_set(
        ca_certs=MQTT_CA_CERT,
        certfile=MQTT_CLIENT_CERT,
        keyfile=MQTT_CLIENT_KEY,
        cert_reqs=ssl.CERT_REQUIRED,
        tls_version=ssl.PROTOCOL_TLS,
        ciphers=None
    )
    
    # Set TLS options
    client.tls_insecure_set(False)  # Don't allow insecure connections
    
    client.on_connect = on_connect
    client.connect(MQTT_BROKER, MQTT_PORT, 60)
    client.loop_start()

def publish_sensor_data():
    try:
        while True:
            # Read sensor data
            heart_rate = max30102.heart_rate
            temperature = mcp9808.temperature
            accel_x, accel_y, accel_z = mpu6050.acceleration
            
            # Create data dictionary
            sensor_data = {
                "heart_rate": round(heart_rate, 1),
                "temperature": round(temperature, 1),
                "acceleration": {
                    "x": round(accel_x, 2),
                    "y": round(accel_y, 2),
                    "z": round(accel_z, 2)
                }
            }
            
            # Publish data
            client.publish(MQTT_TOPIC, json.dumps(sensor_data))
            print("Published:", sensor_data)
            
            time.sleep(1)
            
    except KeyboardInterrupt:
        print("\nStopping MQTT publisher...")
        client.loop_stop()
        client.disconnect()

if __name__ == "__main__":
    print("Starting MQTT publisher...")
    connect_mqtt()
    publish_sensor_data() 