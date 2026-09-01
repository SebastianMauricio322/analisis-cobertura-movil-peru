-- ============================================
-- 04_ANALISIS.SQL
-- Proyecto: Análisis de Cobertura Móvil en Perú
-- Fuente: OSIPTEL — datos abiertos
-- ============================================


-- ============================================
-- Bloque 1: Brecha digital geográfica
-- ============================================

-- 1.1 Porcentaje de centros poblados con 4G por departamento

SELECT departamento,
       COUNT(*) AS total_centros_poblados,
       SUM(tiene_4g) AS cuantos_tienen_4g,
       ROUND((SUM(tiene_4g) * 100.0 / COUNT(*)), 2) AS porcentaje_tienen_4g
FROM cobertura_movil
GROUP BY departamento
ORDER BY porcentaje_tienen_4g DESC;


-- 1.2 Centros poblados sin ninguna tecnología de red (2G/3G/4G/5G)
-- Nota: el resultado es 0 en todo el dataset — hallazgo documentado:
-- todos los centros poblados registrados tienen al menos alguna tecnología.

SELECT departamento,
       COUNT(*) AS cantidad_centros_sin_cobertura
FROM cobertura_movil
WHERE tiene_2g = 0 AND tiene_3g = 0 AND tiene_4g = 0 AND tiene_5g = 0
GROUP BY departamento
ORDER BY cantidad_centros_sin_cobertura DESC;

SELECT COUNT(*) AS total_nacional_sin_cobertura
FROM cobertura_movil
WHERE tiene_2g = 0 AND tiene_3g = 0 AND tiene_4g = 0 AND tiene_5g = 0;


-- 1.3 Centros atrapados en tecnología antigua (solo 2G, sin 3G/4G/5G)

SELECT departamento,
       COUNT(*) AS total_centros_poblados,
       COUNT(*) FILTER (WHERE mejor_tecnologia = '2G') AS centros_2g,
       ROUND((COUNT(*) FILTER (WHERE mejor_tecnologia = '2G') * 100.0 / COUNT(*)), 2) AS porcentaje_solo_2g
FROM cobertura_movil
GROUP BY departamento
ORDER BY porcentaje_solo_2g DESC;


-- ============================================
-- Bloque 2: Competencia entre operadoras
-- ============================================

-- 2.1 Presencia total de cada operadora y % de participación

SELECT empresa_operadora,
       COUNT(*) AS centros_poblados_cubiertos,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM cobertura_movil), 2) AS pct_participacion
FROM cobertura_movil
GROUP BY empresa_operadora
ORDER BY centros_poblados_cubiertos DESC;


-- 2.2 Centros poblados con un solo operador disponible (sin competencia)

SELECT centro_poblado,
       departamento,
       MAX(empresa_operadora) AS unica_operadora,
       COUNT(DISTINCT empresa_operadora) AS cuantas_operadoras
FROM cobertura_movil
GROUP BY centro_poblado, departamento
HAVING COUNT(DISTINCT empresa_operadora) = 1
ORDER BY departamento;


-- 2.3 Operadora líder en 4G por departamento (ranking)
-- Nota: Callao presenta empate real entre Telefónica y Viettel (7 vs 7),
-- documentado como hallazgo — no se fuerza un ganador artificial.

WITH operadoras_4g AS (
    SELECT departamento, empresa_operadora, SUM(tiene_4g) AS cubierto_4g
    FROM cobertura_movil
    GROUP BY departamento, empresa_operadora
),
ranking_operadoras AS (
    SELECT departamento, empresa_operadora, cubierto_4g,
           RANK() OVER (PARTITION BY departamento ORDER BY cubierto_4g DESC) AS ranking
    FROM operadoras_4g
)
SELECT departamento, empresa_operadora, cubierto_4g, ranking
FROM ranking_operadoras
WHERE ranking = 1
ORDER BY departamento;


-- 2.4 Promedio de estaciones base 4G por operadora (solo donde tienen 4G real)
-- Mide inversión en infraestructura, no solo presencia geográfica.

SELECT empresa_operadora,
       ROUND(AVG(cant_eb_4g), 2) AS promedio_estaciones_4g
FROM cobertura_movil
WHERE tiene_4g = 1
GROUP BY empresa_operadora
ORDER BY promedio_estaciones_4g DESC;


-- ============================================
-- Bloque 3: Calidad de red 
-- ============================================

-- 3.1 Porcentaje de centros con velocidad mayor a 1 Mbps por departamento

SELECT departamento,
       COUNT(DISTINCT ubigeo_ccpp) FILTER (WHERE mas_de_1_mbps = 1) AS centros_velocidad_mayor_1mbps,
       COUNT(DISTINCT ubigeo_ccpp) AS total_centros,
       ROUND(COUNT(DISTINCT ubigeo_ccpp) FILTER (WHERE mas_de_1_mbps = 1) * 100.0 / COUNT(DISTINCT ubigeo_ccpp), 2) AS porcentaje
FROM cobertura_movil
GROUP BY departamento
ORDER BY porcentaje DESC;


-- 3.2 Índice de conectividad combinado (4G + velocidad) — ranking nacional

WITH porcentajes_4g_velocidad AS (
    SELECT departamento,
           COUNT(ubigeo_ccpp) AS total_centros_poblados,
           SUM(tiene_4g) AS cuantos_tienen_4g,
           ROUND((SUM(tiene_4g) * 100.0 / COUNT(ubigeo_ccpp)), 2) AS porcentaje_tienen_4g,
           COUNT(DISTINCT ubigeo_ccpp) FILTER (WHERE mas_de_1_mbps = 1) AS centros_velocidad_mayor_1mbps,
           ROUND(COUNT(DISTINCT ubigeo_ccpp) FILTER (WHERE mas_de_1_mbps = 1) * 100.0 / COUNT(DISTINCT ubigeo_ccpp), 2) AS porcentaje_velocidad
    FROM cobertura_movil
    GROUP BY departamento
),
combinacion AS (
    SELECT departamento,
           porcentaje_tienen_4g,
           porcentaje_velocidad,
           (porcentaje_tienen_4g + porcentaje_velocidad) / 2 AS indice_combinado
    FROM porcentajes_4g_velocidad
)
SELECT departamento,
       indice_combinado,
       RANK() OVER (ORDER BY indice_combinado DESC) AS ranking_nacional
FROM combinacion
ORDER BY ranking_nacional;


-- ============================================
-- Bloque 4: Evolución histórica (2010-2019)
-- ============================================

-- 4.1 Crecimiento año a año de cobertura por operadora
-- Se usa el último trimestre reportado de cada año como representativo
-- (la métrica es una fotografía de estado, no un acumulado).

WITH trimestre_anio_alto AS (
    SELECT empresa_operadora, anio, trimestre, centros_con_cobertura,
           ROW_NUMBER() OVER (PARTITION BY anio, empresa_operadora ORDER BY trimestre DESC) AS top
    FROM cobertura_historica
),
anio_anterior AS (
    SELECT empresa_operadora, anio, trimestre, centros_con_cobertura,
           LAG(centros_con_cobertura, 1) OVER (PARTITION BY empresa_operadora ORDER BY anio ASC) AS centros_anio_anterior
    FROM trimestre_anio_alto
    WHERE top = 1
)
SELECT empresa_operadora, anio, trimestre, centros_con_cobertura,
       ROUND(((centros_con_cobertura - centros_anio_anterior) * 100.0 / centros_anio_anterior), 2) AS crecimiento_porcentual
FROM anio_anterior
ORDER BY empresa_operadora, anio;