import time
import board
import busio
import json
import paho.mqtt.client as mqtt
import adafruit_ssd1306
from max30102 import MAX30102
from adafruit_mcp9808 import MCP9808
from adafruit_mpu6050 import MPU6050
from PIL import Image, ImageDraw, ImageFont
import numpy as np
from scipy.signal import find_peaks

# MQTT Configuration
MQTT_BROKER = "localhost"  # Change this to your MQTT broker address
MQTT_PORT = 8883  # Standard secure MQTT port
MQTT_TOPIC = "smart_watch/pc_data"
MQTT_USERNAME = "smart_watch"  # Change this
MQTT_PASSWORD = "your_secure_password"  # Change this

# Initialize I2C bus
i2c = busio.I2C(board.SCL, board.SDA)

# Initialize OLED display (128x64)
oled = adafruit_ssd1306.SSD1306_I2C(128, 64, i2c, addr=0x3C)

# Initialize sensors
max30102 = MAX30102(i2c)
mcp9808 = MCP9808(i2c)
mpu6050 = MPU6050(i2c)

# Configure MAX30102
max30102.setup_sensor()
max30102.set_pulse_amplitude_red(0x0A)
max30102.set_pulse_amplitude_ir(0x0A)

# Heart rate calculation variables
RED_BUFFER_SIZE = 100
red_buffer = np.zeros(RED_BUFFER_SIZE)
last_peak_time = time.time()
current_heart_rate = 0

# Create blank image for drawing
image = Image.new("1", (oled.width, oled.height))
draw = ImageDraw.Draw(image)

# Load default font
font = ImageFont.load_default()

# Initialize MQTT client
client = mqtt.Client()
pc_data = {"status": "Waiting for PC data..."}

def calculate_heart_rate(red_data):
    global last_peak_time, current_heart_rate
    
    # Find peaks in the red data
    peaks, _ = find_peaks(red_data, distance=20, height=np.mean(red_data) + np.std(red_data))
    
    if len(peaks) > 1:
        # Calculate time between peaks
        current_time = time.time()
        time_diff = current_time - last_peak_time
        
        if time_diff > 0:
            # Calculate heart rate (beats per minute)
            beats = len(peaks) - 1
            current_heart_rate = (beats / time_diff) * 60
            last_peak_time = current_time
    
    return current_heart_rate

def on_connect(client, userdata, flags, rc):
    print(f"Connected to MQTT broker with result code: {rc}")
    client.subscribe(MQTT_TOPIC)

def on_message(client, userdata, msg):
    global pc_data
    try:
        pc_data = json.loads(msg.payload.decode())
    except Exception as e:
        print(f"Error processing message: {e}")

def connect_mqtt():
    # Set username and password
    client.username_pw_set(MQTT_USERNAME, MQTT_PASSWORD)
    
    # Set TLS/SSL
    client.tls_set()  # This will use the system's CA certificates
    
    client.on_connect = on_connect
    client.on_message = on_message
    client.connect(MQTT_BROKER, MQTT_PORT, 60)
    client.loop_start()

def clear_display():
    # Clear the display
    draw.rectangle((0, 0, oled.width, oled.height), outline=0, fill=0)
    oled.image(image)
    oled.show()

def update_display(heart_rate, temperature, accel_x, accel_y, accel_z):
    # Clear the display
    clear_display()
    
    # Draw the sensor readings
    draw.text((0, 0), f"HR: {heart_rate:.0f} BPM", font=font, fill=255)
    draw.text((0, 16), f"Temp: {temperature:.1f}°C", font=font, fill=255)
    draw.text((0, 32), f"X: {accel_x:.1f}", font=font, fill=255)
    draw.text((0, 48), f"PC: {pc_data.get('status', 'No data')}", font=font, fill=255)
    
    # Update the display
    oled.image(image)
    oled.show()

def main():
    print("Starting sensor readings...")
    connect_mqtt()
    
    try:
        while True:
            # Read MAX30102 data
            red, ir = max30102.read_sequential()
            
            # Update red buffer
            red_buffer = np.roll(red_buffer, -1)
            red_buffer[-1] = red
            
            # Calculate heart rate
            heart_rate = calculate_heart_rate(red_buffer)
            
            # Read other sensor data
            temperature = mcp9808.temperature
            accel_x, accel_y, accel_z = mpu6050.acceleration
            
            # Update OLED display
            update_display(heart_rate, temperature, accel_x, accel_y, accel_z)
            
            # Print readings to console (for debugging)
            print(f"Heart Rate: {heart_rate:.0f} BPM")
            print(f"Temperature: {temperature:.1f}°C")
            print(f"Acceleration: X={accel_x:.1f}, Y={accel_y:.1f}, Z={accel_z:.1f}")
            print(f"PC Status: {pc_data.get('status', 'No data')}")
            print("-" * 40)
            
            # Wait for 1 second before next reading
            time.sleep(1)
            
    except KeyboardInterrupt:
        print("\nStopping sensor readings...")
        client.loop_stop()
        client.disconnect()
        clear_display()

if __name__ == "__main__":
    main() 