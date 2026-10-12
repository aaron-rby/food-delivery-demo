@echo off
cd /d "%~dp0.."
if not exist config\database.properties (
  echo Copy config\database.example.properties to config\database.properties and fill in your local settings.
  pause
  exit /b 1
)
if not exist lib\ojdbc6.jar (
  echo Add your local Oracle JDBC driver as lib\ojdbc6.jar. See connectivity\README.md.
  pause
  exit /b 1
)
call scripts\build.cmd
if errorlevel 1 (
  echo Build failed. Check that JDK 17 or newer is installed and on PATH.
  pause
  exit /b 1
)
echo Open http://127.0.0.1:8788 after the server prints its Local URL.
java -cp "build;lib\ojdbc6.jar" WebServer config\database.properties
pause
