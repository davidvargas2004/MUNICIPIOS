#!/bin/bash

# --- 1. SETTINGS 
CONTAINER_NAME="herramientas"
DB_NAME="herramientasDB"
ROOT_PASS="root"
HOST_PORT="9090"
LOCAL_CSV="$HOME/Downloads/municipios_task.csv"
VOLUME="$HOME/Documents/coding/dockerUploads"

# --- 2. RESET ---
docker rm -f $CONTAINER_NAME 2>/dev/null

# --- 3. START ---

docker run -d \
  --name $CONTAINER_NAME \
  -p $HOST_PORT:3306 \
  -e MARIADB_ROOT_PASSWORD=$ROOT_PASS \
  -v $VOLUME:/uploads \
  mariadb:latest --local-infile=1

echo "Waiting for MariaDB to wake up..."
sleep 15

# --- 4. COPY ---


# --- 5. SQL ---
docker exec -i $CONTAINER_NAME mariadb -u root -p$ROOT_PASS <<EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME;
USE $DB_NAME;

CREATE TABLE IF NOT EXISTS provincia (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombreProvincia VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS categoria (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tipoCategoria VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS estadoCiclo (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tipoEstado VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS almacen (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombreAlmacen VARCHAR(255) NOT NULL,
    provincia_id INT,
    CONSTRAINT fk_almacen_provincia FOREIGN KEY (provincia_id) REFERENCES provincia(id)
);

CREATE TABLE IF NOT EXISTS producto (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombreProducto VARCHAR(255) NOT NULL,
    caduca TINYINT(1), 
    categoria_id INT,
    CONSTRAINT fk_producto_categoria FOREIGN KEY (categoria_id) REFERENCES categoria(id)
);

CREATE TABLE IF NOT EXISTS movimientos (
    id INT PRIMARY KEY, -- Usamos el ID del CSV
    fecha DATETIME NOT NULL,
    costoAlmacenamiento DECIMAL(12,3),
    cantidad DECIMAL(12,3),
    fechaVencimiento DATETIME NULL,
    almacen_id INT,
    estadoCiclo_id INT,
    producto_id INT,
    CONSTRAINT fk_mov_almacen FOREIGN KEY (almacen_id) REFERENCES almacen(id),
    CONSTRAINT fk_mov_estado FOREIGN KEY (estadoCiclo_id) REFERENCES estadoCiclo(id),
    CONSTRAINT fk_mov_producto FOREIGN KEY (producto_id) REFERENCES producto(id)
);

DROP TABLE IF EXISTS staging_inventario;

CREATE TABLE IF NOT EXISTS staging_inventario (
    id_movimiento VARCHAR(50),
    fecha VARCHAR(100),
    almacen VARCHAR(255),
    provincia VARCHAR(255),
    producto VARCHAR(255),
    categoria VARCHAR(255),
    caduca VARCHAR(50),        
    estado_ciclo VARCHAR(255),
    cantidad VARCHAR(100),      
    costo_almacenamiento VARCHAR(100),
    fecha_vencimiento VARCHAR(100)
);

SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE '/uploads/inventario_ferreteria.csv'
INTO TABLE staging_inventario
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Llenar Provincias
INSERT INTO provincia (nombreProvincia)
SELECT DISTINCT provincia FROM staging_inventario;

-- Llenar Categorías
INSERT INTO categoria (tipoCategoria)
SELECT DISTINCT categoria FROM staging_inventario;

-- Llenar Estados de Ciclo
INSERT INTO estadoCiclo (tipoEstado)
SELECT DISTINCT estado_ciclo FROM staging_inventario;


-- Llenar Almacenes (conectando con el ID de provincia)
INSERT INTO almacen (nombreAlmacen, provincia_id)
SELECT DISTINCT s.almacen, p.id
FROM staging_inventario s
JOIN provincia p ON s.provincia = p.nombreProvincia;


INSERT INTO producto (nombreProducto, caduca, categoria_id)
SELECT DISTINCT s.producto, 
       CASE WHEN s.caduca = 'True' THEN 1 ELSE 0 END, 
       c.id
FROM staging_inventario s
JOIN categoria c ON s.categoria = c.tipoCategoria;


INSERT IGNORE INTO movimientos (
    id, fecha, costoAlmacenamiento, cantidad, fechaVencimiento, 
    almacen_id, estadoCiclo_id, producto_id
)
SELECT 
    s.id_movimiento, 
    s.fecha, 
    s.costo_almacenamiento, 
    s.cantidad, 
    STR_TO_DATE(NULLIF(s.fecha_vencimiento, ''), '%Y-%m-%d %H:%i:%s'),
    a.id, 
    e.id, 
    pr.id
FROM staging_inventario s
JOIN almacen a ON s.almacen = a.nombreAlmacen
JOIN estadoCiclo e ON s.estado_ciclo = e.tipoEstado
JOIN producto pr ON s.producto = pr.nombreProducto;

-- create disparador

DROP TRIGGER IF EXISTS antes_de_actualizar_costo;


DELIMITER //


CREATE TRIGGER antes_de_actualizar_costo
BEFORE UPDATE ON movimientos
FOR EACH ROW
BEGIN
    
    IF NEW.costoAlmacenamiento < 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: No se permiten costos negativos';
    END IF;
    
END //

DELIMITER ;


-- crear sp
DELIMITER //


CREATE PROCEDURE actualizar_costo(
    IN p_id INT, 
    IN p_nuevo_costo DECIMAL(12,3)
)
BEGIN
    
    UPDATE movimientos 
    SET costoAlmacenamiento = p_nuevo_costo 
    WHERE id = p_id;
    
  
    SELECT CONCAT('Movimiento ', p_id, ' actualizado a ', p_nuevo_costo) AS Resultado;
END //


DELIMITER ;


EOF

echo "Process finished"