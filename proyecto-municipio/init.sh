#!/bin/bash

service mariadb start
sleep 15

mysql -uroot << 'EOFSETUP'
CREATE DATABASE IF NOT EXISTS municipios;

DROP TABLE IF EXISTS municipios.municipios;
DROP TABLE IF EXISTS municipios.departamentos;
DROP TABLE IF EXISTS municipios.temp_csv;

CREATE TABLE municipios.departamentos (
  id_departamento VARCHAR(5) PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE municipios.municipios (
  id_municipio VARCHAR(10) PRIMARY KEY,
  id_departamento VARCHAR(5) NOT NULL,
  nombre VARCHAR(100) NOT NULL,
  tipo VARCHAR(50),
  longitud VARCHAR(20),
  latitud VARCHAR(20),
  FOREIGN KEY (id_departamento) REFERENCES municipios.departamentos(id_departamento)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE municipios.temp_csv (
  id_departamento VARCHAR(5),
  nombre_departamento VARCHAR(100),
  id_municipio VARCHAR(10),
  nombre_municipio VARCHAR(100),
  tipo VARCHAR(50),
  longitud VARCHAR(20),
  latitud VARCHAR(20)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

LOAD DATA INFILE '/tmp/Libro1.csv'
INTO TABLE municipios.temp_csv
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(id_departamento, nombre_departamento, id_municipio, nombre_municipio, tipo, longitud, latitud);

INSERT IGNORE INTO municipios.departamentos (id_departamento, nombre)
SELECT DISTINCT id_departamento, nombre_departamento FROM municipios.temp_csv;

INSERT INTO municipios.municipios (id_municipio, id_departamento, nombre, tipo, longitud, latitud)
SELECT id_municipio, id_departamento, nombre_municipio, tipo, longitud, latitud
FROM municipios.temp_csv;

DROP TABLE municipios.temp_csv;

CREATE USER IF NOT EXISTS 'admin'@'localhost' IDENTIFIED BY 'admin123';
CREATE USER IF NOT EXISTS 'admin'@'%' IDENTIFIED BY 'admin123';
GRANT ALL PRIVILEGES ON municipios.* TO 'admin'@'localhost';
GRANT ALL PRIVILEGES ON municipios.* TO 'admin'@'%';
FLUSH PRIVILEGES;

SELECT 'DEPARTAMENTOS' AS tabla, COUNT(*) AS registros FROM municipios.departamentos
UNION ALL
SELECT 'MUNICIPIOS', COUNT(*) FROM municipios.municipios;
EOFSETUP

echo "=========================================="
echo "✅ LISTO - 2 TABLAS CREADAS"
echo "departamentos + municipios (FK)"
echo "=========================================="

tail -f /dev/null

