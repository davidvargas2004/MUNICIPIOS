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



