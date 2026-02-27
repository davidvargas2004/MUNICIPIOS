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

INSERT INTO movimientos_historico (fecha, cantidad) VALUES ('2024-05-15 10:00:00', 50.5);
INSERT INTO movimientos_historico (fecha, cantidad) VALUES ('2026-02-22 14:30:00', 100.0);
INSERT INTO movimientos_historico (fecha, cantidad) VALUES ('2028-12-01 09:00:00', 25.75);
INSERT INTO movimientos_historico (fecha, cantidad) VALUES ('2025-12-20 08:30:00', 12.50);
INSERT INTO movimientos_historico (fecha, cantidad) VALUES ('2026-06-15 11:00:00', 85.00);
INSERT INTO movimientos_historico (fecha, cantidad) VALUES ('2026-11-02 16:45:00', 44.20);
INSERT INTO movimientos_historico (fecha, cantidad) VALUES ('2027-01-10 09:00:00', 150.00);
INSERT INTO movimientos_historico (fecha, cantidad) VALUES ('2028-05-20 10:20:00', 30.00);

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


INSERT INTO catalogo_distribuido (nombre, categoria_id) VALUES ('Taladro Percutor', 2);
INSERT INTO catalogo_distribuido (nombre, categoria_id) VALUES ('Pintura Acrílica', 9);
INSERT INTO catalogo_distribuido (nombre, categoria_id) VALUES ('Caja de Tornillos', 6);
INSERT INTO catalogo_distribuido (nombre, categoria_id) VALUES ('Martillo de Carpintero', 1);
INSERT INTO catalogo_distribuido (nombre, categoria_id) VALUES ('Bolsa de Cemento', 3);
INSERT INTO catalogo_distribuido (nombre, categoria_id) VALUES ('Guantes de Protección', 7);
INSERT INTO catalogo_distribuido (nombre, categoria_id) VALUES ('Taladro Inalámbrico', 2);
INSERT INTO catalogo_distribuido (nombre, categoria_id) VALUES ('Tubo PVC 1/2 pulgada', 4);


SELECT PARTITION_NAME, TABLE_ROWS 
FROM INFORMATION_SCHEMA.PARTITIONS 
WHERE TABLE_NAME = 'catalogo_distribuido';