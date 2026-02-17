#!/bin/bash

# Iniciar MariaDB
service mariadb start
sleep 10

# Crear base de datos y usuario
mysql << 'EOFDB'
CREATE DATABASE IF NOT EXISTS municipios;
CREATE USER IF NOT EXISTS 'admin'@'localhost' IDENTIFIED BY 'admin123';
GRANT ALL PRIVILEGES ON municipios.* TO 'admin'@'localhost';
FLUSH PRIVILEGES;
EOFDB

sleep 3

# Crear tabla y cargar CSV
mysql -u admin -padmin123 municipios << 'EOFCSV'
DROP TABLE IF EXISTS municipios;

CREATE TABLE municipios (
  id_departamento VARCHAR(5),
  nombre_departamento VARCHAR(100),
  id_municipio VARCHAR(10),
  nombre_municipio VARCHAR(100),
  tipo VARCHAR(50),
  longitud VARCHAR(20),
  latitud VARCHAR(20),
  PRIMARY KEY (id_municipio)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

LOAD DATA LOCAL INFILE '/tmp/Libro1.csv'
INTO TABLE municipios
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ';'
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(id_departamento, nombre_departamento, id_municipio, nombre_municipio, tipo, longitud, latitud);

SELECT CONCAT('✓ CSV CARGADO: ', COUNT(*), ' municipios') AS resultado FROM municipios;
EOFCSV

echo "=========================================="
echo "✅ MariaDB LISTO - Puerto 3307"
echo "=========================================="
echo "Conectar: mysql -u admin -padmin123 municipios"
echo "=========================================="

# Mantener contenedor activo
tail -f /dev/null
