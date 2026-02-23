SELECT AVG(costoAlmacenamiento) as pCosto
FROM movimientos;


SELECT UPPER(nombreProducto) FROM producto;

SELECT LOWER(nombreProducto) FROM
producto;


SELECT  CONCAT('Almacen',':',nombreAlmacen) as nombre FROM almacen;

SELECT  SUM(cantidad) as cantidadTotal FROM movimientos;



