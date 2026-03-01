
/*
--------------------------
Primer experimento
--------------------------
*/

-- PostgreSQL / MySQL
-- Crear tabla
CREATE TABLE test_pk (id INT PRIMARY KEY, val TEXT);
INSERT INTO test_pk SELECT g, md5(random()::text) FROM generate_series(1, 10000000) g;

-- Query (PostgreSQL)
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM test_pk WHERE id = 500000;
-- Query (MySQL)
EXPLAIN SELECT * FROM test_pk WHERE id = 500000;

/*
--------------------------
Segundo experimento
--------------------------
*/

-- MySQL (Ejecutar por separado)
CREATE TABLE tabla_int (id SERIAL PRIMARY KEY, data CHAR(255));
CREATE TABLE tabla_uuid (id CHAR(36) PRIMARY KEY, data CHAR(255));

-- Insertar 5 millones
-- (Nota: Para UUID, usar INSERT INTO tabla_uuid SELECT UUID(), ...)

-- Medir fragmentación
SELECT 
    relname AS nombre_tabla,
    pg_size_pretty(pg_total_relation_size(relname::regclass)) AS tamaño_total
FROM pg_stat_user_tables
WHERE relname = 'tabla_int';
SELECT 
    relname AS nombre_tabla,
    pg_size_pretty(pg_total_relation_size(relname::regclass)) AS tamaño_total
FROM pg_stat_user_tables
WHERE relname = 'tabla_uuid';

/*
--------------------------
Tercer experimento
--------------------------
*/
CREATE TABLE transacciones (
    id SERIAL PRIMARY KEY,
    usuario_id INT,
    monto DECIMAL(10,2),
    fecha TIMESTAMP,
    detalle TEXT
);

-- Poblar la tabla para trabajar (mínimo necesario)
INSERT INTO transacciones (usuario_id, monto, fecha, detalle)
SELECT 
    floor(random() * 1000), 
    (random() * 100)::numeric(10,2), 
    NOW(), 
    'Transaccion de prueba'
FROM generate_series(1, 100000);
-- PostgreSQL
SELECT n_dead_tup, n_live_tup FROM pg_stat_user_tables WHERE relname = 'transacciones';

-- Ejecutar 1,000,000 updates
UPDATE transacciones SET monto = monto + 1;

-- Verificar bloat
SELECT n_dead_tup FROM pg_stat_user_tables WHERE relname = 'transacciones';

-- Limpiar
VACUUM ANALYZE transacciones;

/*
--------------------------
Cuarto experimento
--------------------------
*/
CREATE TABLE ventas (
    id SERIAL PRIMARY KEY,
    region VARCHAR(50),
    total DECIMAL(10,2),
    fecha DATE,
    col1 TEXT, col2 TEXT, col3 TEXT, col4 TEXT, 
    col5 TEXT, col6 TEXT, col7 TEXT, col8 TEXT, 
    col9 TEXT, col10 TEXT, col11 TEXT, col12 TEXT
);

-- 2. Carga de datos (100,000 registros para pruebas rápidas; escala a 10M para el reporte)
INSERT INTO ventas (region, total, fecha, col1, col2, col3, col4, col5, col6, col7, col8, col9, col10, col11, col12)
SELECT 
    (ARRAY['Norte', 'Sur', 'Este', 'Oeste'])[floor(random() * 4) + 1],
    (random() * 1000)::numeric(10,2),
    CURRENT_DATE - (random() * 365)::integer,
    'data', 'data', 'data', 'data', 'data', 'data', 'data', 'data', 'data', 'data', 'data', 'data'
FROM generate_series(1, 100000);
-- Query A: Lee todas las columnas (SELECT *)
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM ventas WHERE region = 'Norte';

-- Query B: Lee solo 2 columnas (Agregación)
EXPLAIN (ANALYZE, BUFFERS) SELECT SUM(total), COUNT(*) FROM ventas WHERE region = 'Norte';

/*
--------------------------
Quinto experiment bonus
--------------------------
*/
-- Crear índice cubriente
CREATE INDEX idx_ventas_covering ON ventas(region) INCLUDE (total);

-- Re-ejecutar Query B
EXPLAIN (ANALYZE, BUFFERS) SELECT SUM(total), COUNT(*) FROM ventas WHERE region = 'Norte';