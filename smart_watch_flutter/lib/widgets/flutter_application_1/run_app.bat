@echo off
echo Starting Smart Watch X1 Application...

:: Activate virtual environment
echo Activating virtual environment...
call .\.venv\Scripts\activate

:: Start the API server in a new window
echo Starting API server...
start cmd /k "python api_server.py"

:: Wait a few seconds for the API server to start
timeout /t 5

:: Run Flutter app
echo Starting Flutter app...
flutter run

:: Keep the window open if there's an error
pause 