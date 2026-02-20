#!/bin/bash

# --- 1. SETTINGS 
CONTAINER_NAME="colombiadb"
DB_NAME="colombia_db"
ROOT_PASS="root"
HOST_PORT="5050"
LOCAL_CSV="$HOME/Downloads/municipios_task.csv"

# --- 2. RESET ---
docker rm -f $CONTAINER_NAME 2>/dev/null

# --- 3. START ---

docker run -d \
  --name $CONTAINER_NAME \
  -p $HOST_PORT:3306 \
  -e MARIADB_ROOT_PASSWORD=$ROOT_PASS \
  mariadb:latest --local-infile=1

echo "Waiting for MariaDB to wake up..."
sleep 15

# --- 4. COPY ---

sed -i 's/\r//' "$LOCAL_CSV"
docker cp "$LOCAL_CSV" $CONTAINER_NAME:/tmp/data.csv

# --- 5. SQL ---
docker exec -i $CONTAINER_NAME mariadb -u root -p$ROOT_PASS <<EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME;
USE $DB_NAME;
CREATE TABLE IF NOT EXISTS municipios (
    region VARCHAR(255),
    codigo_depto INT,
    nombre_depto VARCHAR(255),
    codigo_muni INT,
    nombre_muni VARCHAR(255)
);
SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE '/tmp/data.csv'
INTO TABLE municipios
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS

(region, codigo_depto, nombre_depto, @valor_muni, nombre_muni, @columna_vacia)
-- Transformamos el valor con punto antes de guardarlo
SET codigo_muni = REPLACE(@valor_muni, '.', '');
EOF

echo "Process finished"