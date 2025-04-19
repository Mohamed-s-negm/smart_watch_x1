# smart_watch_x1
The first attempt into making a full smart watch system using fusion 360.

I have successfully made the schematics, PCB, and the 3D PCB. I have also prepared the structure design and imported the 3D PCB into it.

The photos shows the design.
![Alt text](./Design_Pics/Full_Schematics.png)
![Alt text](./Design_Pics/Full_PCB.png)
![Alt text](./Design_Pics/3D_PCB.png)
![Alt text](./Design_Pics/Full_Structure.png)
![Alt text](./Design_Pics/Full_Structure_inside.png)

The main components used are:
1- MCU: ESP32.
2- MAX30102. (Heart beat rate sensor)
3- MPU6050. (Accelerometer & Gyroscope)
4- MCP9808. (Temperature Sensor)
5- TP4056. (Charging System)
6- Li-Battery.
7- The other components such as capacitors, leds, etc.

--------------------------------------------------------------
Next, I start with the coding process.

The main.cpp file contains the code that will be used for the ESP32 to obtain the values from the sensors.

Since, we are not using a real version, we can't get real values so we have to create our own dataset.

I obtained a dataset of 10000 samples from chatgpt.

First, in the data_generate file, I grouped every 10 samples together into a group then shuffled the groups.
The second step will be to make another dataset from the existing one but instead of showing the data of the sensors, I want the slope, the change and the average of the data of each 10 samples.
Depending on the change should be the factor for the machine learning model later to decide which state is the user at.

