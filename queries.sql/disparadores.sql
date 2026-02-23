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

CALL actualizar_costo(1, -100.000);