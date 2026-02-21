@echo off
cd /d %~dp0

REM --- 1. SETTINGS ---
SET CONTAINER_NAME=colombiadb
SET DB_NAME=colombia_db
SET ROOT_PASS=root
SET HOST_PORT=5050
SET LOCAL_CSV=C:\Users\RSP-L20-LW-022\Downloads\municipios.csv


REM --- 2. RESET ---
docker rm -f %CONTAINER_NAME% 2>nul

REM --- 3. START ---
docker run -d ^
  --name %CONTAINER_NAME% ^
  -p %HOST_PORT%:3306 ^
  -e MARIADB_ROOT_PASSWORD=%ROOT_PASS% ^
  mariadb:latest --local-infile=1

echo Waiting for MariaDB to wake up...
timeout /t 20 /nobreak >nul

REM --- 4. COPY ---
echo Copiando CSV...
docker cp "%LOCAL_CSV%" %CONTAINER_NAME%:/tmp/data.csv

REM --- Verificar que el archivo llego ---
docker exec %CONTAINER_NAME% ls -lh /tmp/data.csv
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: El CSV no se copio correctamente. Verifica la ruta.
    pause
    exit /b 1
)

REM --- 5. SQL ---
(
  echo CREATE DATABASE IF NOT EXISTS %DB_NAME%;
  echo USE %DB_NAME%;
  echo CREATE TABLE IF NOT EXISTS municipios ^(
  echo     codigo_depto VARCHAR^(10^),
  echo     nombre_depto VARCHAR^(100^),
  echo     codigo_muni VARCHAR^(10^),
  echo     nombre_muni VARCHAR^(100^),
  echo     tipo VARCHAR^(100^),
  echo     longitud DECIMAL^(11, 8^),
  echo     latitud DECIMAL^(11, 8^)
  echo ^);
  echo SET GLOBAL local_infile = 1;
  echo LOAD DATA LOCAL INFILE '/tmp/data.csv'
  echo INTO TABLE municipios
  echo CHARACTER SET utf8
  echo FIELDS TERMINATED BY ','
  echo ENCLOSED BY '"'
  echo LINES TERMINATED BY '\n'
  echo IGNORE 1 ROWS;
) > "%TEMP%\municipios_setup.sql"

docker exec -i %CONTAINER_NAME% mariadb -u root -p%ROOT_PASS% --local-infile=1 < "%TEMP%\municipios_setup.sql"

del "%TEMP%\municipios_setup.sql" 2>nul

REM --- Verificar registros ---
docker exec -i %CONTAINER_NAME% mariadb -u root -p%ROOT_PASS% -e "USE %DB_NAME%; SELECT COUNT(*) AS total FROM municipios;"

echo Process finished, go look to vsCode mate.
pause
