@echo off
echo ==================================
echo PASO 1: Eliminando contenedor anterior si existe...
docker rm -f municipio 2>nul

echo.
echo PASO 2: Construyendo imagen Docker...
docker build -t municipio-img .

echo.
echo PASO 3: Levantando contenedor municipio con MariaDB...
docker run -d --name municipio -p 3306:3306 municipio-img

echo.
echo PASO 4: Esperando que MariaDB arranque...
timeout /t 8 /nobreak

echo.
echo PASO 5: Abriendo Visual Studio Code...
code .

echo.
echo ==================================
echo PROYECTO LISTO
echo Usa Docker extension en VS Code
echo Conectate al contenedor "municipio"
echo ==================================
pause
