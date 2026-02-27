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

INSERT INTO producto (id, nombreProducto, caduca, categoria_id) 
VALUES (500, 'Herramienta de Prueba', 1, 1);