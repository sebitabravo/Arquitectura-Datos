-- ========================================
-- SCRIPT DE CREACIÓN DATA WAREHOUSE COVID-19
-- Autor: Sebastián Bravo
-- Fecha: Julio 2025
-- ========================================

-- Crear base de datos
CREATE DATABASE IF NOT EXISTS dw_defunciones_covid;
USE dw_defunciones_covid;

-- ========================================
-- DIMENSIONES
-- ========================================

-- Dimensión Tiempo
CREATE TABLE dim_tiempo (
    fecha_id INT PRIMARY KEY,
    fecha_completa DATE NOT NULL,
    año INT NOT NULL,
    mes INT NOT NULL,
    dia INT NOT NULL,
    trimestre INT NOT NULL,
    semestre INT NOT NULL,
    nombre_mes VARCHAR(20),
    nombre_dia VARCHAR(20),
    dia_semana INT,
    es_fin_semana BOOLEAN,
    es_feriado BOOLEAN DEFAULT FALSE,
    semana_año INT,
    INDEX idx_año (año),
    INDEX idx_mes (año, mes),
    INDEX idx_fecha (fecha_completa)
);

-- Dimensión Ubicación
CREATE TABLE dim_ubicacion (
    ubicacion_id INT PRIMARY KEY AUTO_INCREMENT,
    codigo_comuna INT NOT NULL,
    nombre_comuna VARCHAR(100) NOT NULL,
    codigo_region INT,
    nombre_region VARCHAR(100) NOT NULL,
    zona_geografica ENUM('Norte', 'Centro', 'Sur', 'Austral') NOT NULL,
    es_capital_regional BOOLEAN DEFAULT FALSE,
    poblacion_estimada INT,
    superficie_km2 DECIMAL(10,2),
    densidad_poblacional DECIMAL(10,2),
    UNIQUE KEY uk_comuna (codigo_comuna),
    INDEX idx_region (nombre_region),
    INDEX idx_zona (zona_geografica)
);

-- Dimensión Persona
CREATE TABLE dim_persona (
    persona_id INT PRIMARY KEY AUTO_INCREMENT,
    sexo ENUM('Hombre', 'Mujer', 'No especificado') NOT NULL,
    edad INT NOT NULL,
    rango_edad VARCHAR(20) NOT NULL,
    grupo_etario ENUM('Infantil', 'Juvenil', 'Adulto', 'Adulto Mayor') NOT NULL,
    decada_edad VARCHAR(20),
    INDEX idx_sexo (sexo),
    INDEX idx_edad (edad),
    INDEX idx_grupo (grupo_etario)
);

-- Dimensión Diagnóstico
CREATE TABLE dim_diagnostico (
    diagnostico_id INT PRIMARY KEY AUTO_INCREMENT,
    codigo_diag VARCHAR(10) NOT NULL,
    tipo_covid ENUM('Confirmado', 'Sospechoso', 'Relacionado') NOT NULL,
    capitulo_diag VARCHAR(10),
    glosa_capitulo VARCHAR(255),
    codigo_grupo VARCHAR(10),
    glosa_grupo VARCHAR(255),
    codigo_categoria VARCHAR(10),
    glosa_categoria VARCHAR(255),
    codigo_subcategoria VARCHAR(10),
    glosa_subcategoria VARCHAR(500),
    es_causa_principal BOOLEAN DEFAULT TRUE,
    UNIQUE KEY uk_diagnostico (codigo_diag, tipo_covid),
    INDEX idx_tipo (tipo_covid),
    INDEX idx_codigo (codigo_diag)
);

-- Dimensión Lugar de Defunción
CREATE TABLE dim_lugar_defuncion (
    lugar_id INT PRIMARY KEY AUTO_INCREMENT,
    tipo_lugar ENUM('Hospital o Clínica', 'Domicilio', 'Otro', 'No especificado') NOT NULL,
    es_establecimiento_salud BOOLEAN DEFAULT FALSE,
    INDEX idx_tipo_lugar (tipo_lugar)
);

-- ========================================
-- TABLA DE HECHOS
-- ========================================

CREATE TABLE fact_defunciones_covid (
    defuncion_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    fecha_id INT NOT NULL,
    ubicacion_id INT NOT NULL,
    persona_id INT NOT NULL,
    diagnostico_id INT NOT NULL,
    lugar_id INT NOT NULL,
    
    -- Métricas
    cantidad_defunciones INT DEFAULT 1,
    edad_fallecimiento INT NOT NULL,
    dias_desde_inicio_pandemia INT,
    
    -- Campos de auditoría
    fecha_carga TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fuente_datos VARCHAR(50) DEFAULT 'DEIS',
    
    -- Foreign Keys
    CONSTRAINT fk_fecha FOREIGN KEY (fecha_id) 
        REFERENCES dim_tiempo(fecha_id),
    CONSTRAINT fk_ubicacion FOREIGN KEY (ubicacion_id) 
        REFERENCES dim_ubicacion(ubicacion_id),
    CONSTRAINT fk_persona FOREIGN KEY (persona_id) 
        REFERENCES dim_persona(persona_id),
    CONSTRAINT fk_diagnostico FOREIGN KEY (diagnostico_id) 
        REFERENCES dim_diagnostico(diagnostico_id),
    CONSTRAINT fk_lugar FOREIGN KEY (lugar_id) 
        REFERENCES dim_lugar_defuncion(lugar_id),
    
    -- Índices para consultas
    INDEX idx_fecha_ubicacion (fecha_id, ubicacion_id),
    INDEX idx_diagnostico_fecha (diagnostico_id, fecha_id),
    INDEX idx_ubicacion_persona (ubicacion_id, persona_id)
);

-- ========================================
-- TABLAS DE AGREGACIÓN (OPCIONAL)
-- ========================================

-- Agregación mensual por región
CREATE TABLE agg_mensual_region (
    año INT NOT NULL,
    mes INT NOT NULL,
    ubicacion_id INT NOT NULL,
    total_defunciones INT NOT NULL,
    promedio_edad DECIMAL(5,2),
    defunciones_hombres INT,
    defunciones_mujeres INT,
    PRIMARY KEY (año, mes, ubicacion_id),
    CONSTRAINT fk_agg_ubicacion FOREIGN KEY (ubicacion_id) 
        REFERENCES dim_ubicacion(ubicacion_id)
);

-- ========================================
-- VISTAS ÚTILES
-- ========================================

-- Vista de resumen diario
CREATE VIEW v_resumen_diario AS
SELECT 
    t.fecha_completa,
    t.año,
    t.mes,
    t.nombre_mes,
    u.nombre_region,
    u.nombre_comuna,
    COUNT(*) as total_defunciones,
    AVG(f.edad_fallecimiento) as edad_promedio,
    SUM(CASE WHEN p.sexo = 'Hombre' THEN 1 ELSE 0 END) as hombres,
    SUM(CASE WHEN p.sexo = 'Mujer' THEN 1 ELSE 0 END) as mujeres
FROM fact_defunciones_covid f
JOIN dim_tiempo t ON f.fecha_id = t.fecha_id
JOIN dim_ubicacion u ON f.ubicacion_id = u.ubicacion_id
JOIN dim_persona p ON f.persona_id = p.persona_id
GROUP BY t.fecha_completa, u.nombre_region, u.nombre_comuna;

-- Vista de análisis por grupo etario
CREATE VIEW v_analisis_grupo_etario AS
SELECT 
    t.año,
    t.trimestre,
    p.grupo_etario,
    p.sexo,
    u.zona_geografica,
    COUNT(*) as total_defunciones,
    AVG(f.edad_fallecimiento) as edad_promedio
FROM fact_defunciones_covid f
JOIN dim_tiempo t ON f.fecha_id = t.fecha_id
JOIN dim_persona p ON f.persona_id = p.persona_id
JOIN dim_ubicacion u ON f.ubicacion_id = u.ubicacion_id
GROUP BY t.año, t.trimestre, p.grupo_etario, p.sexo, u.zona_geografica;

-- ========================================
-- PROCEDIMIENTOS ALMACENADOS
-- ========================================

DELIMITER //

-- Procedimiento para cargar dimensión tiempo
CREATE PROCEDURE sp_cargar_dim_tiempo(
    IN fecha_inicio DATE,
    IN fecha_fin DATE
)
BEGIN
    DECLARE fecha_actual DATE;
    SET fecha_actual = fecha_inicio;
    
    WHILE fecha_actual <= fecha_fin DO
        INSERT INTO dim_tiempo (
            fecha_id,
            fecha_completa,
            año,
            mes,
            dia,
            trimestre,
            semestre,
            nombre_mes,
            nombre_dia,
            dia_semana,
            es_fin_semana,
            semana_año
        ) VALUES (
            YEAR(fecha_actual) * 10000 + MONTH(fecha_actual) * 100 + DAY(fecha_actual),
            fecha_actual,
            YEAR(fecha_actual),
            MONTH(fecha_actual),
            DAY(fecha_actual),
            QUARTER(fecha_actual),
            CASE WHEN MONTH(fecha_actual) <= 6 THEN 1 ELSE 2 END,
            MONTHNAME(fecha_actual),
            DAYNAME(fecha_actual),
            DAYOFWEEK(fecha_actual),
            CASE WHEN DAYOFWEEK(fecha_actual) IN (1, 7) THEN TRUE ELSE FALSE END,
            WEEK(fecha_actual)
        );
        
        SET fecha_actual = DATE_ADD(fecha_actual, INTERVAL 1 DAY);
    END WHILE;
END//

-- Procedimiento para generar rangos de edad
CREATE PROCEDURE sp_generar_rangos_edad()
BEGIN
    DECLARE i INT DEFAULT 0;
    
    WHILE i <= 110 DO
        INSERT INTO dim_persona (sexo, edad, rango_edad, grupo_etario, decada_edad)
        SELECT 
            sexo,
            i,
            CASE 
                WHEN i < 1 THEN 'Menor a 1 año'
                WHEN i BETWEEN 1 AND 4 THEN '1-4 años'
                WHEN i BETWEEN 5 AND 9 THEN '5-9 años'
                WHEN i BETWEEN 10 AND 14 THEN '10-14 años'
                WHEN i BETWEEN 15 AND 19 THEN '15-19 años'
                WHEN i BETWEEN 20 AND 29 THEN '20-29 años'
                WHEN i BETWEEN 30 AND 39 THEN '30-39 años'
                WHEN i BETWEEN 40 AND 49 THEN '40-49 años'
                WHEN i BETWEEN 50 AND 59 THEN '50-59 años'
                WHEN i BETWEEN 60 AND 69 THEN '60-69 años'
                WHEN i BETWEEN 70 AND 79 THEN '70-79 años'
                WHEN i BETWEEN 80 AND 89 THEN '80-89 años'
                ELSE '90+ años'
            END,
            CASE 
                WHEN i < 15 THEN 'Infantil'
                WHEN i BETWEEN 15 AND 29 THEN 'Juvenil'
                WHEN i BETWEEN 30 AND 59 THEN 'Adulto'
                ELSE 'Adulto Mayor'
            END,
            CONCAT(FLOOR(i/10)*10, 's')
        FROM (SELECT 'Hombre' as sexo UNION SELECT 'Mujer' UNION SELECT 'No especificado') s;
        
        SET i = i + 1;
    END WHILE;
END//

DELIMITER ;

-- ========================================
-- ÍNDICES ADICIONALES PARA OPTIMIZACIÓN
-- ========================================

CREATE INDEX idx_fact_fecha_region 
    ON fact_defunciones_covid(fecha_id, ubicacion_id);

CREATE INDEX idx_fact_diagnostico 
    ON fact_defunciones_covid(diagnostico_id);

CREATE INDEX idx_fact_edad 
    ON fact_defunciones_covid(edad_fallecimiento);

-- ========================================
-- GRANTS (EJEMPLO)
-- ========================================

-- Usuario para ETL
CREATE USER IF NOT EXISTS 'etl_user'@'localhost' IDENTIFIED BY 'password_seguro';
GRANT ALL PRIVILEGES ON dw_defunciones_covid.* TO 'etl_user'@'localhost';

-- Usuario para reportes (solo lectura)
CREATE USER IF NOT EXISTS 'report_user'@'%' IDENTIFIED BY 'password_seguro';
GRANT SELECT ON dw_defunciones_covid.* TO 'report_user'@'%';

FLUSH PRIVILEGES;

-- ========================================
-- INICIALIZACIÓN
-- ========================================

-- Cargar dimensión tiempo para el período de análisis
CALL sp_cargar_dim_tiempo('2019-01-01', '2022-12-31');

-- Generar combinaciones de persona
CALL sp_generar_rangos_edad();
