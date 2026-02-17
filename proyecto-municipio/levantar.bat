@echo off
cd /d %~dp0
echo ==========================================
echo   PROYECTO MUNICIPIOS - INICIALIZANDO
echo ==========================================

echo.
echo [1/5] Limpiando contenedor anterior...
docker rm -f municipio 2>nul
docker rmi municipio-img 2>nul

echo.
echo [2/5] Construyendo imagen Docker...
docker build -t municipio-img .

IF ERRORLEVEL 1 (
    echo.
    echo ❌ ERROR EN BUILD - Verifica Dockerfile
    pause
    exit /b 1
)

echo.
echo [3/5] Levantando contenedor en puerto 3307...
docker run -d --name municipio -p 3307:3306 municipio-img

IF ERRORLEVEL 1 (
    echo.
    echo ❌ ERROR AL LEVANTAR CONTENEDOR
    pause
    exit /b 1
)

echo.
echo [4/5] Esperando carga de CSV (30 segundos)...
timeout /t 30 /nobreak >nul

echo.
echo [5/5] Verificando logs del contenedor...
docker logs municipio | findstr "CSV CARGADO"

echo.
echo [6/5] Abriendo Visual Studio Code...
code .

echo.
echo ==========================================
echo   ✅ PROYECTO LISTO
echo ==========================================
echo.
echo Conectar desde contenedor:
echo   mysql -u admin -padmin123 municipios
echo.
echo Conectar desde host (Windows):
echo   mysql -u admin -padmin123 -h 127.0.0.1 -P 3307 municipios
echo.
echo Verificar datos:
echo   SELECT COUNT(*) FROM municipios;
echo ==========================================
pause
