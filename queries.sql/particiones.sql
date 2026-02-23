CREATE TABLE movimientos_historico (
    id INT,
    fecha DATETIME,
    cantidad DECIMAL(12,3),
    PRIMARY KEY (id, fecha)
)
PARTITION BY RANGE (YEAR(fecha)) (
    PARTITION p_viejo VALUES LESS THAN (2026),
    PARTITION p_actual VALUES LESS THAN (2027),
    PARTITION p_futuro VALUES LESS THAN MAXVALUE
);


INSERT INTO movimientos_historico (id, fecha, cantidad) 
VALUES (1, '2024-05-15 10:00:00', 50.5);


INSERT INTO movimientos_historico (id, fecha, cantidad) 
VALUES (2, '2026-02-22 14:30:00', 100.0);


INSERT INTO movimientos_historico (id, fecha, cantidad) 
VALUES (3, '2028-12-01 09:00:00', 25.75);

SELECT PARTITION_NAME, TABLE_ROWS 
FROM INFORMATION_SCHEMA.PARTITIONS 
WHERE TABLE_NAME = 'movimientos_historico';





CREATE TABLE catalogo_distribuido (
    id INT NOT NULL,
    nombre VARCHAR(100),
    categoria_id INT NOT NULL,
    PRIMARY KEY (id, categoria_id)
)
PARTITION BY LIST (categoria_id) (
    PARTITION p_ferreteria_tecnica VALUES IN (1, 2),
    PARTITION p_construccion_insumos VALUES IN (3, 4, 5, 9),
    PARTITION p_varios VALUES IN (6, 7, 8, 10)
);


INSERT INTO catalogo_distribuido VALUES (1, 'Taladro Percutor', 2);


INSERT INTO catalogo_distribuido VALUES (2, 'Pintura Acrílica', 9);

-- Va a p_varios (Cat 6)
INSERT INTO catalogo_distribuido VALUES (3, 'Caja de Tornillos', 6);


SELECT PARTITION_NAME, TABLE_ROWS 
FROM INFORMATION_SCHEMA.PARTITIONS 
WHERE TABLE_NAME = 'catalogo_distribuido';