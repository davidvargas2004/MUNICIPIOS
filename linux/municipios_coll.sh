#!/bin/bash

# --- 1. SETTINGS 
CONTAINER_NAME="colombiadb"
DB_NAME="colombia_db"
ROOT_PASS="root"
HOST_PORT="5050"
LOCAL_CSV="$HOME/Downloads/municipios.csv"

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
docker cp "$LOCAL_CSV" $CONTAINER_NAME:/tmp/data.csv

# --- 5. SQL ---
docker exec -i $CONTAINER_NAME mariadb -u root -p$ROOT_PASS <<EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME;
USE $DB_NAME;
CREATE TABLE IF NOT EXISTS municipios (
    codigo_depto VARCHAR(10),
    nombre_depto VARCHAR(100),
    codigo_muni VARCHAR(10),
    nombre_muni VARCHAR(100),
    tipo VARCHAR(100),
    longitud DECIMAL(11, 8),
    latitud DECIMAL(11, 8)
);
SET GLOBAL local_infile = 1;
LOAD DATA LOCAL INFILE '/tmp/data.csv'
INTO TABLE municipios
CHARACTER SET utf8
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
EOF

echo "Process finished go look to vsCode mate."