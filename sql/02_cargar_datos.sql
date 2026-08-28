-- ============================================
-- CARGA DE DATOS CRUDOS
-- ============================================

-- NOTA: La carga se realizó mediante el importador
-- visual de DBeaver debido a restricciones de rutas
-- en Windows con el comando COPY nativo de PostgreSQL.
-- El comando equivalente sería:

-- COPY cobertura_movil
-- FROM '/ruta/cobertura_movil_osiptel.csv'
-- DELIMITER ';'
-- CSV HEADER
-- ENCODING 'LATIN1';

-- COPY cobertura_historica
-- FROM '/ruta/cobertura_historica_limpia.csv'
-- DELIMITER ','
-- CSV HEADER
-- ENCODING 'UTF8';

-- Verificación post-carga
SELECT COUNT(*) AS filas_cobertura_movil FROM cobertura_movil;
SELECT COUNT(*) AS filas_cobertura_historica FROM cobertura_historica;