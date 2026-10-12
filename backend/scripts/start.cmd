@echo off
cd /d "%~dp0..\.."
if not exist backend\config\database.properties (
  echo Copy backend\config\database.example.properties to backend\config\database.properties and fill in your local settings.
  pause
  exit /b 1
)
if not exist backend\lib\ojdbc6.jar (
  echo Add your local Oracle JDBC driver as backend\lib\ojdbc6.jar. See docs\connectivity\README.md.
  pause
  exit /b 1
)
call backend\scripts\build.cmd
if errorlevel 1 (
  echo Build failed. Check that JDK 17 or newer is installed and on PATH.
  pause
  exit /b 1
)
echo Open http://127.0.0.1:8788 after the server prints its Local URL.
java -cp "build;backend\lib\ojdbc6.jar" WebServer backend\config\database.properties
pause
