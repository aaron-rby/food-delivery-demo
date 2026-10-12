@echo off
cd /d "%~dp0..\.."
if not exist build mkdir build
javac -d build backend\FoodService.java backend\WebServer.java backend\tests\Phase2Test.java
exit /b %errorlevel%
