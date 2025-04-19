#include <Wire.h>
#include <MPU6050.h>
#include <MAX30105.h>
#include <heartRate.h>
#include <Adafruit_MCP9808.h>

MPU6050 locSensor;
MAX30102 hrSensor;
long lastBeat = 0;
Adafruit_MCP9808 tempSensor = Adafruit_MCP9808();
#define BATTERY_PIN 36;

void setup() {
  // put your setup code here, to run once:
  Serial.being(115200);
  Wire.begin(21,22);

  locSensor.initialize();
  if(locSensor.testConnection()){
    Serial.println("MPU6050 is connected.");
  } else{
    Serial.println("MPU6050 is not connected.");
  }

  if(!hrSensor.begin(Wire, I2C_SPEED_STANDARD)){
    Serial.println("MAX30102 is not connected.");
    while(1);
  }
  hrSensor.setup();

  if(!tempSensor.begin(0x18)){
    Serial.println("MCP9808 is not connected.")
    while(1);
  }

  analogReadResolution(12);

}

void loop() {
  // put your main code here, to run repeatedly:
  Serial.println("Sensors readings:")

  init16_t ax, ay, az, gx, gy, gz;
  locSensor.getMotion6(&ax, &ay, &az, &gx, &gy, &gz);
  Serial.print("MPU6050 accel (X, Y, Z): ");
  Serial.print(ax); Serial.print(", ");
  Serial.print(ay); Serial.print(", ");
  Serial.print(az);

  long irValue = hrSensor.getIR();
  Serial.print("MAX30102 IR: "); Serial.println(irValue);
  if(checkForBeat(irValue)){
    long delta = millis() - lastBeat;
    lastBeat = millis();
    float bpm = 60 / (delta/1000);
    Serial.print("Heart Rate (BPM): "); Serial.println(bpm);
  }

  float tempC = tempSensor.readTempC();
  Serial.print("Temperature (°C): "); Serial.println(tempC);

  int adcValue = analogRead(BATTERY_PIN);
  float voltage = (adcValue / 4095) * 3.3 * 2;
  Serial.print("Battery Voltage: "); Serial.print(voltage); Serial.println("V");

  delay(1000);
}
