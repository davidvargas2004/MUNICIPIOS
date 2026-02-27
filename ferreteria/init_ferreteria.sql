-- ========================================================
-- FERRETERIA_DW COMPLETA - CORREGIDA (Ignora Duplicados PK)
-- ========================================================

DROP DATABASE IF EXISTS ferreteria_dw;
CREATE DATABASE ferreteria_dw 
  DEFAULT CHARACTER SET utf8mb4 
  DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE ferreteria_dw;

-- ========================================================
-- 1. STAGING 
-- ========================================================
DROP TABLE IF EXISTS stg_inventario;
CREATE TABLE stg_inventario (
  id_movimiento VARCHAR(20),
  fecha VARCHAR(50),
  almacen VARCHAR(150),
  provincia VARCHAR(100),
  producto VARCHAR(200),
  categoria VARCHAR(150),
  caduca VARCHAR(10),
  estado_ciclo VARCHAR(150),
  cantidad VARCHAR(50),
  costo_almacenamiento VARCHAR(50),
  fecha_vencimiento VARCHAR(50)
);

-- Cargar CSV
LOAD DATA INFILE '/import/inventario_ferreteria.csv'
INTO TABLE stg_inventario
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
  id_movimiento, @fecha, almacen, provincia, producto, categoria,
  caduca, estado_ciclo, cantidad, costo_almacenamiento, @fecha_venc
)
SET 
  fecha = NULLIF(@fecha, ''),
  fecha_vencimiento = NULLIF(@fecha_venc, '');

SELECT 'STAGING CARGADO' AS paso1, COUNT(*) AS filas FROM stg_inventario;

-- ========================================================
-- 2. DIMENSIONES
-- ========================================================
DROP TABLE IF EXISTS fact_movimiento, dim_estado_ciclo, dim_producto, dim_categoria, dim_almacen, dim_provincia;

CREATE TABLE dim_provincia (
  id_provincia INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL UNIQUE
);
INSERT INTO dim_provincia (nombre)
SELECT DISTINCT TRIM(COALESCE(provincia,'SIN_PROVINCIA'))
FROM stg_inventario WHERE TRIM(COALESCE(provincia,'')) <> '';

CREATE TABLE dim_almacen (
  id_almacen INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(150) NOT NULL UNIQUE,
  id_provincia INT,
  FOREIGN KEY (id_provincia) REFERENCES dim_provincia(id_provincia)
);
INSERT INTO dim_almacen (nombre, id_provincia)
SELECT DISTINCT TRIM(COALESCE(almacen,'SIN_ALMACEN')), p.id_provincia
FROM stg_inventario s
JOIN dim_provincia p ON p.nombre = COALESCE(TRIM(s.provincia),'SIN_PROVINCIA')
WHERE TRIM(COALESCE(s.almacen,'')) <> '';

CREATE TABLE dim_categoria (
  id_categoria INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(150) NOT NULL UNIQUE
);
INSERT INTO dim_categoria (nombre)
SELECT DISTINCT TRIM(COALESCE(categoria,'SIN_CATEGORIA'))
FROM stg_inventario WHERE TRIM(COALESCE(categoria,'')) <> '';

CREATE TABLE dim_producto (
  id_producto INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(200) NOT NULL,
  id_categoria INT NOT NULL,
  caduca BOOLEAN NOT NULL DEFAULT 0,
  UNIQUE KEY uq_producto (nombre, id_categoria),
  FOREIGN KEY (id_categoria) REFERENCES dim_categoria(id_categoria)
);
INSERT INTO dim_producto (nombre, id_categoria, caduca)
SELECT DISTINCT 
  TRIM(COALESCE(producto,'SIN_PRODUCTO')),
  c.id_categoria,
  CASE WHEN LOWER(TRIM(COALESCE(caduca,'false'))) = 'true' THEN 1 ELSE 0 END
FROM stg_inventario s
JOIN dim_categoria c ON c.nombre = COALESCE(TRIM(s.categoria),'SIN_CATEGORIA')
WHERE TRIM(COALESCE(s.producto,'')) <> '';

CREATE TABLE dim_estado_ciclo (
  id_estado INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(150) NOT NULL UNIQUE
);
INSERT INTO dim_estado_ciclo (nombre)
SELECT DISTINCT TRIM(COALESCE(estado_ciclo,'SIN_ESTADO'))
FROM stg_inventario WHERE TRIM(COALESCE(estado_ciclo,'')) <> '';

SELECT 'DIMENSIONES CREADAS' AS paso2;

-- ========================================================
-- 3. TABLA DE HECHOS 
-- ========================================================
CREATE TABLE fact_movimiento (
  id_movimiento BIGINT PRIMARY KEY,
  fecha DATETIME NOT NULL,
  id_almacen INT NOT NULL,
  id_producto INT NOT NULL,
  id_estado INT NULL,
  cantidad DECIMAL(12,2) NULL,
  costo_almacenamiento DECIMAL(12,2) NULL,
  fecha_vencimiento DATETIME NULL,
  
  KEY idx_fecha (fecha),
  KEY idx_almacen (id_almacen),
  KEY idx_producto (id_producto),
  
  FOREIGN KEY (id_almacen) REFERENCES dim_almacen(id_almacen),
  FOREIGN KEY (id_producto) REFERENCES dim_producto(id_producto),
  FOREIGN KEY (id_estado) REFERENCES dim_estado_ciclo(id_estado)
);

-- Cargar hechos con IGNORE para saltar ids duplicados
INSERT IGNORE INTO fact_movimiento
SELECT 
  CAST(TRIM(s.id_movimiento) AS UNSIGNED),
  STR_TO_DATE(TRIM(COALESCE(s.fecha,'1900-01-01')), '%Y-%m-%d %H:%i:%s'),
  a.id_almacen,
  pr.id_producto,
  e.id_estado,
  CASE 
    WHEN TRIM(COALESCE(s.cantidad, '')) = '' THEN NULL 
    ELSE CAST(REPLACE(s.cantidad,',','.') AS DECIMAL(12,2)) 
  END,
  CASE 
    WHEN TRIM(COALESCE(s.costo_almacenamiento, '')) = '' THEN NULL 
    ELSE CAST(REPLACE(s.costo_almacenamiento,',','.') AS DECIMAL(12,2)) 
  END,
  CASE 
    WHEN TRIM(COALESCE(s.fecha_vencimiento,'')) = '' THEN NULL
    ELSE STR_TO_DATE(TRIM(s.fecha_vencimiento), '%Y-%m-%d %H:%i:%s')
  END
FROM stg_inventario s
JOIN dim_almacen a ON a.nombre = TRIM(COALESCE(s.almacen,'SIN_ALMACEN'))
JOIN dim_producto pr ON pr.nombre = TRIM(COALESCE(s.producto,'SIN_PRODUCTO'))
LEFT JOIN dim_estado_ciclo e ON e.nombre = TRIM(COALESCE(s.estado_ciclo,'SIN_ESTADO'))
WHERE s.id_movimiento IS NOT NULL AND TRIM(s.id_movimiento) <> '';

SELECT 'FACT CARGADA' AS paso3, COUNT(*) AS movimientos FROM fact_movimiento;

-- ========================================================
-- 4. VISTAS
-- ========================================================
CREATE OR REPLACE VIEW vista_movimientos AS
SELECT 
  f.id_movimiento, f.fecha,
  a.nombre AS almacen, p.nombre AS provincia,
  pr.nombre AS producto, c.nombre AS categoria,
  pr.caduca, e.nombre AS estado,
  f.cantidad, f.costo_almacenamiento, f.fecha_vencimiento
FROM fact_movimiento f
JOIN dim_almacen a ON a.id_almacen = f.id_almacen
JOIN dim_provincia p ON p.id_provincia = a.id_provincia
JOIN dim_producto pr ON pr.id_producto = f.id_producto
JOIN dim_categoria c ON c.id_categoria = pr.id_categoria
LEFT JOIN dim_estado_ciclo e ON e.id_estado = f.id_estado;

-- ========================================================
-- 5. FUNCIONES
-- ========================================================
DELIMITER //
CREATE FUNCTION fn_costo_total(cant DECIMAL(12,2), costo DECIMAL(12,2))
RETURNS DECIMAL(14,2) DETERMINISTIC
RETURN IFNULL(cant,0) * IFNULL(costo,0); //

CREATE FUNCTION fn_meses_para_vencer(fecha_ven DATETIME)
RETURNS INT DETERMINISTIC
RETURN CASE 
  WHEN fecha_ven IS NULL THEN NULL
  ELSE TIMESTAMPDIFF(MONTH, CURDATE(), fecha_ven)
END; //
DELIMITER ;

-- ========================================================
-- 6. PROCEDIMIENTOS
-- ========================================================
DELIMITER //
CREATE PROCEDURE sp_resumen_categoria(IN p_ini DATE, IN p_fin DATE)
BEGIN
  SELECT c.nombre AS categoria,
         COUNT(*) AS movimientos,
         SUM(f.cantidad) AS total_unidades,
         SUM(fn_costo_total(f.cantidad, f.costo_almacenamiento)) AS costo_total
  FROM fact_movimiento f
  JOIN dim_producto pr ON pr.id_producto = f.id_producto
  JOIN dim_categoria c ON c.id_categoria = pr.id_categoria
  WHERE f.fecha >= p_ini AND f.fecha <= p_fin
  GROUP BY c.nombre
  ORDER BY costo_total DESC;
END //

CREATE PROCEDURE sp_vencidos_proximos()
BEGIN
  SELECT pr.nombre, COUNT(*) AS stock, AVG(f.costo_almacenamiento) AS costo_prom,
         MIN(f.fecha_vencimiento) AS vence_proximo
  FROM fact_movimiento f
  JOIN dim_producto pr ON pr.id_producto = f.id_producto
  WHERE pr.caduca = 1 AND f.fecha_vencimiento IS NOT NULL
    AND f.fecha_vencimiento <= DATE_ADD(CURDATE(), INTERVAL 90 DAY)
  GROUP BY pr.nombre;
END //
DELIMITER ;

-- ========================================================
-- 7. TRIGGERS
-- ========================================================
DELIMITER //
CREATE TRIGGER trg_fact_validar_venc
BEFORE INSERT ON fact_movimiento
FOR EACH ROW
BEGIN
  IF NEW.fecha_vencimiento IS NOT NULL AND NEW.fecha_vencimiento < NEW.fecha THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Fecha vencimiento no puede ser anterior';
  END IF;
END //

CREATE TRIGGER trg_fact_calcular_costo
BEFORE UPDATE ON fact_movimiento
FOR EACH ROW
BEGIN
  IF NEW.cantidad IS NOT NULL AND NEW.costo_almacenamiento IS NOT NULL THEN
    SET NEW.costo_almacenamiento = fn_costo_total(NEW.cantidad, NEW.costo_almacenamiento);
  END IF;
END //
DELIMITER ;

-- ========================================================
-- 8. EVENTOS (scheduler ON)
-- ========================================================
SET GLOBAL event_scheduler = ON;

DELIMITER //
CREATE EVENT IF NOT EXISTS ev_limpiar_staging
ON SCHEDULE EVERY 1 WEEK
DO
  TRUNCATE TABLE stg_inventario; //

CREATE EVENT IF NOT EXISTS ev_resumen_mensual
ON SCHEDULE EVERY 1 MONTH
DO
  INSERT IGNORE INTO resumen_mensual (mes, total_mov, costo_total)
  SELECT DATE_FORMAT(fecha,'%Y-%m-01'), COUNT(*), SUM(fn_costo_total(cantidad,costo_almacenamiento))
  FROM fact_movimiento WHERE fecha >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
  GROUP BY DATE_FORMAT(fecha,'%Y-%m-01'); //
DELIMITER ;

CREATE TABLE IF NOT EXISTS resumen_mensual (
  mes DATE PRIMARY KEY,
  total_mov INT,
  costo_total DECIMAL(16,2)
);

-- ========================================================
-- 9. ÍNDICES OPTIMIZADOS
-- ========================================================
CREATE INDEX idx_fact_fecha_opt ON fact_movimiento(fecha);
CREATE INDEX idx_prod_caduca_opt ON dim_producto(caduca);
CREATE INDEX idx_fact_cant_opt ON fact_movimiento(cantidad);

-- ========================================================
-- 10. VISTA FINAL
-- ========================================================
CREATE OR REPLACE VIEW vw_resumen_categorias AS
SELECT c.nombre, 
       COUNT(f.id_movimiento) AS total_movimientos,
       SUM(f.cantidad) AS unidades,
       SUM(fn_costo_total(f.cantidad, f.costo_almacenamiento)) AS costo_total
FROM fact_movimiento f
JOIN dim_producto p ON p.id_producto = f.id_producto
JOIN dim_categoria c ON c.id_categoria = p.id_categoria
GROUP BY c.nombre;

-- ========================================================
-- ¡LISTO! Mensaje final
-- ========================================================
SELECT 
  '🎉 BASE DE DATOS CREADA EXITOSAMENTE' AS ESTADO,
  (SELECT COUNT(*) FROM fact_movimiento) AS movimientos,
  (SELECT COUNT(*) FROM dim_producto) AS productos,
  (SELECT COUNT(*) FROM dim_categoria) AS categorias;
