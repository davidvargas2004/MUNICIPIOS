
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


SELECT id, costoAlmacenamiento FROM movimientos WHERE id = 1;

CALL actualizar_costo(1, 99.99);