-- ============================================
-- 03_LIMPIEZA.SQL
-- Proyecto: Análisis de Cobertura Móvil Perú
-- ============================================

-- ============================================
-- Sección 1: Diagnóstico inicial
-- ============================================

-- 1. Visión general del dataset
SELECT COUNT(*) AS total_filas 
FROM cobertura_movil;

-- 2. Operadoras disponibles y distribución
SELECT empresa_operadora, COUNT(*) AS registros
FROM cobertura_movil
GROUP BY empresa_operadora
ORDER BY registros DESC;

-- 3. Periodo disponible
SELECT DISTINCT periodo FROM cobertura_movil;

-- 4. Distribución de tecnologías
SELECT
    SUM(tiene_2g) AS centros_con_2g,
    SUM(tiene_3g) AS centros_con_3g,
    SUM(tiene_4g) AS centros_con_4g,
    SUM(tiene_5g) AS centros_con_5g
FROM cobertura_movil;

-- 5. Nulos por columna crítica
SELECT
    COUNT(*) FILTER (WHERE empresa_operadora IS NULL) AS nulos_operadora,
    COUNT(*) FILTER (WHERE departamento IS NULL)      AS nulos_departamento,
    COUNT(*) FILTER (WHERE distrito IS NULL)          AS nulos_distrito,
    COUNT(*) FILTER (WHERE latitud IS NULL)           AS nulos_latitud,
    COUNT(*) FILTER (WHERE longitud IS NULL)          AS nulos_longitud,
    COUNT(*) FILTER (WHERE tiene_4g IS NULL)          AS nulos_4g,
    COUNT(*) FILTER (WHERE cant_eb_5g IS NULL)        AS nulos_eb5g
FROM cobertura_movil;

-- 6. Coordenadas fuera del rango de Perú
SELECT COUNT(*) AS coords_fuera_rango
FROM cobertura_movil
WHERE latitud NOT BETWEEN -18.5 AND 0
   OR longitud NOT BETWEEN -81.5 AND -68.5;

-- 7. Centros poblados sin ninguna tecnología
SELECT COUNT(*) AS sin_cobertura
FROM cobertura_movil
WHERE tiene_2g = 0 AND tiene_3g = 0
  AND tiene_4g = 0 AND tiene_5g = 0;

-- 8. Verificar cobertura historica
SELECT anio, trimestre, empresa_operadora, centros_con_cobertura
FROM cobertura_historica
ORDER BY anio, trimestre
LIMIT 10;

-- ============================================
-- Sección 2: Transformaciones
-- ============================================

-- 1. Convertir PERIODO a fecha real
ALTER TABLE cobertura_movil ADD COLUMN periodo_fecha DATE;

UPDATE cobertura_movil
SET periodo_fecha = TO_DATE(CAST(periodo AS TEXT), 'YYYYMM');

-- 2. Convertir FECHA_CORTE a fecha real
ALTER TABLE cobertura_movil ADD COLUMN fecha_corte_date DATE;

UPDATE cobertura_movil
SET fecha_corte_date = TO_DATE(fecha_corte, 'YYYYMMDD');

-- 3. Agregar columna de generación de red
-- Clasifica cada registro según la mejor tecnología disponible
ALTER TABLE cobertura_movil ADD COLUMN mejor_tecnologia VARCHAR(5);

UPDATE cobertura_movil
SET mejor_tecnologia = CASE
    WHEN tiene_5g = 1 THEN '5G'
    WHEN tiene_4g = 1 THEN '4G'
    WHEN tiene_3g = 1 THEN '3G'
    WHEN tiene_2g = 1 THEN '2G'
    ELSE 'Sin cobertura'
END;

-- 4. Agregar columna de acceso a internet real
-- Se considera internet real tener 4G o velocidad mayor a 1Mbps
ALTER TABLE cobertura_movil ADD COLUMN tiene_internet_real SMALLINT;

UPDATE cobertura_movil
SET tiene_internet_real = CASE
    WHEN tiene_4g = 1 OR mas_de_1_mbps = 1 THEN 1
    ELSE 0
END;

-- ============================================
-- Sección 3: Verificación final
-- ============================================

-- Distribución de mejor tecnología por operadora
SELECT
    empresa_operadora,
    mejor_tecnologia,
    COUNT(*) AS centros
FROM cobertura_movil
GROUP BY empresa_operadora, mejor_tecnologia
ORDER BY empresa_operadora, mejor_tecnologia;

-- Resumen de internet real
SELECT
    SUM(tiene_internet_real) AS con_internet_real,
    COUNT(*) - SUM(tiene_internet_real) AS sin_internet_real,
    ROUND(SUM(tiene_internet_real) * 100.0 / COUNT(*), 2) AS pct_con_internet
FROM cobertura_movil;

-- ============================================
-- Corrección: Inconsistencia de mayúsculas/minúsculas
-- en nombres de departamento (Puno, PUNO)
-- ============================================

-- Diagnóstico antes de corregir
SELECT DISTINCT departamento
FROM cobertura_movil
ORDER BY departamento;

-- Estandarizar a mayúsculas y eliminar espacios extra
UPDATE cobertura_movil
SET departamento = UPPER(TRIM(departamento));

-- Verificar que quedó correcto
SELECT DISTINCT departamento, COUNT(*) 
FROM cobertura_movil
GROUP BY departamento
ORDER BY departamento;
