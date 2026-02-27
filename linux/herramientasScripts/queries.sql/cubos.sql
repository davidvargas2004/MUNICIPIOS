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


SELECT * FROM cubo_inventario;