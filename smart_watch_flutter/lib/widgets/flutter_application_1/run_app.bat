@echo off
echo Starting Smart Watch X1 application...

:: Activate virtual environment
echo Activating virtual environment...
call .\.venv\Scripts\activate

:: Start the combined API server
echo Starting API server...
start cmd /k "python combined_server.py"

:: Wait for the server to start
timeout /t 5

:: Start the Flutter app
echo Starting Flutter app...
start cmd /k "flutter run"

echo Application started!
echo Please make sure to update the serverUrl in lib/fridge_page.dart with your computer's IP address.
echo You can find your IP address by running 'ipconfig' in a command prompt. 