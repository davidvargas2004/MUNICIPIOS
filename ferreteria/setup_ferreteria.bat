@echo off
set "CSV_PATH=C:\ferreteria\inventario_ferreteria.csv"
set "WORK_DIR=C:\ferreteria"
set "SCRIPT_SQL=init_ferreteria.sql"

echo === VERIFICANDO ===
if not exist "%CSV_PATH%" ( echo ERROR CSV no encontrado: %CSV_PATH% & pause & exit /b 1 )
if not exist "%WORK_DIR%\%SCRIPT_SQL%" ( echo ERROR SQL no encontrado & pause & exit /b 1 )

cd /d "%WORK_DIR%"

REM Limpiar
docker rm -f ferreteria-mysql >nul 2>&1

REM MySQL en PUERTO 3307 (evita conflicto)
docker run -d ^
  --name ferreteria-mysql ^
  -p 3307:3306 ^
  -e MYSQL_ROOT_PASSWORD=Root123! ^
  -e MYSQL_DATABASE=ferreteria_dw ^
  -v "C:\ferreteria":/import ^
  -v ferreteria_data:/var/lib/mysql ^
  mysql:8.0 ^
  --secure-file-priv=/import ^
  --local-infile=1

timeout /t 15 /nobreak >nul

REM Ejecutar SQL
docker exec -i ferreteria-mysql mysql -uroot -pRoot123! ferreteria_dw < "%SCRIPT_SQL%"

REM VSCode
start code "%WORK_DIR%"

echo.
echo ✅ LISTO! Conecta en VSCode:
echo Host: localhost  Puerto: 3307  User: root  Pass: Root123!  DB: ferreteria_dw
docker exec ferreteria-mysql mysql -uroot -pRoot123! ferreteria_dw -e "SHOW TABLES;"
pause
