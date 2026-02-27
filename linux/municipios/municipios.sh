#!/bin/bash

# --- SETTINGS 
CONTAINER_NAME="colombiadb"
DB_NAME="colombia_db"
ROOT_PASS="root"
HOST_PORT="5050"
LOCAL_CSV="$HOME/Downloads/municipios.csv"
VOLUME="$HOME/Documents/coding/dockerUploads"

# --- RESET ---
docker rm -f $CONTAINER_NAME 2>/dev/null

# --- START ---

docker run -d \
  --name $CONTAINER_NAME \
  -p $HOST_PORT:3306 \
  -e MARIADB_ROOT_PASSWORD=$ROOT_PASS \
  -v $VOLUME:/uploads \
  mariadb:latest --local-infile=1

echo "Waiting for MariaDB to wake up..."
sleep 15



# --- SQL ---
docker exec -i $CONTAINER_NAME mariadb -u root -p$ROOT_PASS <<EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME;
USE $DB_NAME;

CREATE TABLE tipoMunicipio(
  id INT AUTO_INCREMENT PRIMARY KEY,
  tipo VARCHAR(100)
);

CREATE TABLE departamento(
  id INT PRIMARY KEY,
  nombreDepartamento VARCHAR(100)
);

CREATE TABLE municipio (
  id INT PRIMARY KEY,
  nombreMunicipio VARCHAR(100),
  longitud DECIMAL(11,8),
  latitud DECIMAL(11,8),
  tipoMunicipio_id INT,
  departamento_id INT,
  FOREIGN KEY (tipoMunicipio_id) REFERENCES tipoMunicipio(id),
  FOREIGN KEY (departamento_id) REFERENCES departamento(id)
);

CREATE TEMPORARY TABLE staging (
  cod_depto INT,
  nom_depto VARCHAR(100),
  cod_muni INT,
  nom_muni VARCHAR(100),
  tipo_texto VARCHAR(100), 
  longitud DECIMAL(11,8),
  latitud DECIMAL(11,8)
);

SET GLOBAL local_infile = 1;
LOAD DATA LOCAL INFILE '/uploads/municipios.csv' 
INTO TABLE staging 
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 LINES;

INSERT INTO tipoMunicipio (tipo) 
SELECT DISTINCT tipo_texto FROM staging;

INSERT INTO departamento (id, nombreDepartamento) 
SELECT DISTINCT cod_depto, nom_depto FROM staging;

INSERT INTO municipio (id, nombreMunicipio, longitud, latitud, tipoMunicipio_id, departamento_id)
SELECT 
  s.cod_muni, 
  s.nom_muni, 
  s.longitud, 
  s.latitud, 
  t.id,        
  s.cod_depto  
FROM staging s
JOIN tipoMunicipio t ON s.tipo_texto = t.tipo;

DROP TABLE staging;

EOF

echo "Process finished go look to vsCode mate."