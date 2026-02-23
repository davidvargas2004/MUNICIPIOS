CREATE INDEX  fecha_mov ON movimientos(fecha);

SHOW INDEX FROM movimientos;


SELECT * FROM movimientos WHERE fecha = '2026-02-20';