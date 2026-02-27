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


CREATE OR REPLACE VIEW almacenUbicacion as

SELECT
a.id as almacenID,
a.nombreAlmacen,
p.id as provinciaID,
p.nombreProvincia

from almacen a

INNER JOIN provincia p
ON a.provincia_id = p.id;


CREATE OR REPLACE VIEW categoriaProducto as

SELECT 
p.id as productoID,
p.caduca,
c.id as categoriaID,
c.tipoCategoria

from  producto p
INNER JOIN categoria c
ON p.categoria_id = c.id;


CREATE TABLE movimientos_historico (
    id INT AUTO_INCREMENT,
    fecha DATETIME,
    cantidad DECIMAL(12,3),
    PRIMARY KEY (id, fecha)
)
PARTITION BY RANGE (YEAR(fecha)) (
    PARTITION p_viejo VALUES LESS THAN (2026),
    PARTITION p_actual VALUES LESS THAN (2027),
    PARTITION p_futuro VALUES LESS THAN MAXVALUE
);


INSERT INTO movimientos_historico (fecha, cantidad) VALUES ('2024-05-15 10:00:00', 50.5);
INSERT INTO movimientos_historico (fecha, cantidad) VALUES ('2026-02-22 14:30:00', 100.0);
INSERT INTO movimientos_historico (fecha, cantidad) VALUES ('2028-12-01 09:00:00', 25.75);
INSERT INTO movimientos_historico (fecha, cantidad) VALUES ('2025-12-20 08:30:00', 12.50);
INSERT INTO movimientos_historico (fecha, cantidad) VALUES ('2026-06-15 11:00:00', 85.00);
INSERT INTO movimientos_historico (fecha, cantidad) VALUES ('2026-11-02 16:45:00', 44.20);
INSERT INTO movimientos_historico (fecha, cantidad) VALUES ('2027-01-10 09:00:00', 150.00);
INSERT INTO movimientos_historico (fecha, cantidad) VALUES ('2028-05-20 10:20:00', 30.00);


CREATE TABLE catalogo_distribuido (
    id INT NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(100),
    categoria_id INT NOT NULL,
    PRIMARY KEY (id, categoria_id)
)

PARTITION BY LIST (categoria_id) (
    PARTITION p_ferreteria_tecnica VALUES IN (1, 2),
    PARTITION p_construccion_insumos VALUES IN (3, 4, 5, 9),
    PARTITION p_varios VALUES IN (6, 7, 8, 10)
);


INSERT INTO catalogo_distribuido (nombre, categoria_id) VALUES ('Taladro Percutor', 2);
INSERT INTO catalogo_distribuido (nombre, categoria_id) VALUES ('Pintura Acrílica', 9);
INSERT INTO catalogo_distribuido (nombre, categoria_id) VALUES ('Caja de Tornillos', 6);
INSERT INTO catalogo_distribuido (nombre, categoria_id) VALUES ('Martillo de Carpintero', 1);
INSERT INTO catalogo_distribuido (nombre, categoria_id) VALUES ('Bolsa de Cemento', 3);
INSERT INTO catalogo_distribuido (nombre, categoria_id) VALUES ('Guantes de Protección', 7);
INSERT INTO catalogo_distribuido (nombre, categoria_id) VALUES ('Taladro Inalámbrico', 2);
INSERT INTO catalogo_distribuido (nombre, categoria_id) VALUES ('Tubo PVC 1/2 pulgada', 4);



CREATE OR REPLACE VIEW cubo_inventario AS
SELECT 
    IFNULL(pr.nombreProvincia, 'TOTAL GENERAL') AS Provincia,
    IFNULL(c.tipoCategoria, 'Total Provincia') AS Categoria,
    SUM(m.cantidad) AS Stock_Total,
    SUM(m.cantidad * m.costoAlmacenamiento) AS Valor_Total_Almacenado
FROM movimientos m
JOIN almacen a ON m.almacen_id = a.id
JOIN provincia pr ON a.provincia_id = pr.id
JOIN producto p ON m.producto_id = p.id
JOIN categoria c ON p.categoria_id = c.id
GROUP BY pr.nombreProvincia, c.tipoCategoria WITH ROLLUP;


SET GLOBAL event_scheduler = ON;

CREATE TABLE producto_historial LIKE producto;

TRUNCATE table producto_historial;


DELIMITER //

CREATE EVENT respaldo_productos_automatico
ON SCHEDULE EVERY 50 SECOND
DO
BEGIN
    INSERT IGNORE INTO producto_historial 
    SELECT * FROM producto;
END //

DELIMITER ;


DELIMITER //
CREATE FUNCTION calcular_descuento(p_precio DECIMAL(12,2), p_porcentaje INT) 
RETURNS DECIMAL(12,2)
DETERMINISTIC
BEGIN
    DECLARE v_resultado DECIMAL(12,2);
    
    SET v_resultado = p_precio * (1 - (p_porcentaje / 100));
    RETURN v_resultado;
END //
DELIMITER ;


EOF

echo "Process finished"
code .