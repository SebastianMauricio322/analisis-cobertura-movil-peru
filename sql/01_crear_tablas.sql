-- ============================================
-- PROYECTO: Análisis de Cobertura Móvil Perú
-- Fuente: OSIPTEL — datos abiertos
-- Periodo: Marzo 2023
-- ============================================

-- Tabla principal: cobertura móvil por centro poblado y operadora
CREATE TABLE cobertura_movil (
    num                 INTEGER,
    fecha_corte         VARCHAR(10),
    periodo             INTEGER,
    empresa_operadora   VARCHAR(100),
    ubigeo_ccpp         VARCHAR(10),
    ubigeo_distrito     VARCHAR(10),
    departamento        VARCHAR(60),
    provincia           VARCHAR(60),
    distrito            VARCHAR(60),
    centro_poblado      VARCHAR(150),
    latitud             DECIMAL(10,6),
    longitud            DECIMAL(10,6),
    tiene_2g            SMALLINT,
    tiene_3g            SMALLINT,
    tiene_4g            SMALLINT,
    tiene_5g            SMALLINT,
    voz                 SMALLINT,
    sms                 SMALLINT,
    mms                 SMALLINT,
    hasta_1_mbps        SMALLINT,
    mas_de_1_mbps       SMALLINT,
    cant_eb_2g          INTEGER,
    cant_eb_3g          INTEGER,
    cant_eb_4g          INTEGER,
    cant_eb_5g          INTEGER
);

-- Tabla secundaria: evolución histórica de centros poblados con cobertura
CREATE TABLE cobertura_historica (
    anio                INTEGER,
    trimestre           VARCHAR(5),
    empresa_operadora   VARCHAR(100),
    centros_con_cobertura INTEGER
);