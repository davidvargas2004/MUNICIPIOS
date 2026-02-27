SELECT AVG(costoAlmacenamiento) as pCosto
FROM movimientos;


SELECT UPPER(nombreProducto) FROM producto;

SELECT LOWER(nombreProducto) FROM
producto;


SELECT  CONCAT('Almacen',':',nombreAlmacen) as nombre FROM almacen;

SELECT  SUM(cantidad) as cantidadTotal FROM movimientos;


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


SELECT 
    id, 
    costoAlmacenamiento as 'Original', 
    calcular_descuento(costoAlmacenamiento, 15) as 'Con Descuento'
FROM movimientos;