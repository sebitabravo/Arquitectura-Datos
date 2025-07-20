# Informe Técnico: Data Warehouse de Defunciones COVID-19

## 1. Resumen Ejecutivo

Este proyecto implementa un sistema de data warehouse para el análisis de defunciones relacionadas con COVID-19 en Chile. Utilizando datos oficiales del DEIS que abarcan desde 1990 hasta 2022, se ha desarrollado un proceso ETL que identifica y extrae específicamente los registros relacionados con COVID-19, resultando en un dataset de 55,060 defunciones para análisis.

### Hallazgos Principales:
- **Impacto Total**: 55,060 defunciones asociadas a COVID-19 (2019-2022)
- **Año Peak**: 2021 con 22,946 defunciones (41.7% del total)
- **Reducción de Datos**: De 832 MB a 15.4 MB (98% de optimización)

## 2. Contexto del Proyecto

### 2.1 Problema de Negocio
La pandemia de COVID-19 requiere análisis detallados de mortalidad para:
- Evaluar el impacto real de la pandemia
- Identificar grupos poblacionales vulnerables
- Apoyar decisiones de políticas públicas
- Monitorear tendencias y proyecciones

### 2.2 Fuente de Datos
- **Origen**: Departamento de Estadísticas e Información de Salud (DEIS)
- **Cobertura**: Nacional (todas las regiones de Chile)
- **Período**: 1990-2022 (datos COVID desde 2019)
- **Volumen**: ~2.7 millones de registros totales

## 3. Arquitectura Técnica

### 3.1 Pipeline ETL

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Datos Fuente   │────▶│  Procesamiento   │────▶│ Data Warehouse  │
│   (CSV 832MB)   │     │   Python/Pandas  │     │  (CSV 15.4MB)   │
└─────────────────┘     └──────────────────┘     └─────────────────┘
         │                       │                         │
         │                       │                         │
    Lectura por            Filtrado COVID           Modelo Dimensional
      Chunks              Transformaciones            Optimizado
```

### 3.2 Tecnologías Utilizadas
- **Lenguaje**: Python 3.x
- **Librería Principal**: Pandas
- **Control de Versiones**: Git + Git LFS
- **Almacenamiento**: CSV (fase inicial)

## 4. Modelo de Datos

### 4.1 Esquema Estrella Propuesto

```
                    ┌─────────────────┐
                    │ FACT_DEFUNCIONES│
                    │   - fecha_id    │
     ┌──────────────│   - ubicacion_id│──────────────┐
     │              │   - persona_id  │              │
     │              │   - diagnostico │              │
     │              │   - cantidad    │              │
     │              └─────────────────┘              │
     │                       │                       │
     ▼                       ▼                       ▼
┌──────────┐          ┌──────────┐           ┌──────────┐
│DIM_TIEMPO│          │DIM_PERSONA│          │DIM_UBICAC│
│- fecha_id│          │- persona_id│         │- ubic_id │
│- año     │          │- sexo      │         │- comuna  │
│- mes     │          │- edad_grupo│         │- region  │
│- trimestre│         │- rango_edad│         │- zona    │
└──────────┘          └──────────┘           └──────────┘
```

### 4.2 Granularidad
- **Nivel de Detalle**: Una fila por defunción
- **Dimensiones Conformadas**: Tiempo, Ubicación, Persona
- **Métricas**: Conteo de defunciones, tasas calculadas

## 5. Análisis de Calidad de Datos

### 5.1 Completitud
- Campos críticos con 100% completitud:
  - Fecha de defunción
  - Sexo
  - Edad
  - Comuna/Región
  - Diagnóstico principal

### 5.2 Validaciones Implementadas
- Filtrado por códigos ICD-10 específicos (U07.1, U07.2)
- Búsqueda de texto en diagnósticos
- Normalización de formatos

### 5.3 Limitaciones Identificadas
- Posible subregistro en 2019 (solo 1 caso)
- Variabilidad en codificación entre años
- Dependencia de certificación médica

## 6. Insights del Análisis Exploratorio

### 6.1 Evolución Temporal
```
2019: ▌ (1 caso)
2020: ████████████████████ (18,680)
2021: ████████████████████████ (22,946)
2022: ██████████████ (13,433)
```

### 6.2 Distribución Geográfica
- Mayor concentración en Región Metropolitana
- Correlación con densidad poblacional
- Variabilidad rural vs urbana

### 6.3 Perfil Demográfico
- Mayor mortalidad en adultos mayores
- Diferencias por sexo observables
- Patrones por grupos etarios

## 7. Casos de Uso del Data Warehouse

### 7.1 Reportería Operacional
- Dashboard diario de defunciones
- Alertas de tendencias anómalas
- Reportes para autoridades sanitarias

### 7.2 Análisis Estratégico
- Evaluación de políticas públicas
- Planificación de recursos hospitalarios
- Estudios epidemiológicos

### 7.3 Investigación
- Análisis de factores de riesgo
- Estudios de mortalidad comparada
- Proyecciones y modelamiento

## 8. Plan de Implementación

### Fase 1: MVP (Actual)
- ✅ Script ETL funcional
- ✅ Datos filtrados y limpios
- ✅ Documentación básica

### Fase 2: Base de Datos (Próximo)
- [ ] Migración a PostgreSQL/MySQL
- [ ] Implementación del modelo dimensional
- [ ] Automatización de cargas

### Fase 3: Visualización
- [ ] Conexión con herramientas BI
- [ ] Dashboards interactivos
- [ ] Reportes automatizados

### Fase 4: Avanzado
- [ ] Machine Learning para predicciones
- [ ] Integración con otros datasets
- [ ] API para consultas

## 9. Consideraciones de Seguridad y Privacidad

### 9.1 Datos Sensibles
- No contiene identificadores personales
- Datos agregados a nivel comuna
- Cumple con normativas de privacidad

### 9.2 Acceso y Permisos
- Definir roles de usuario
- Logs de auditoría
- Encriptación en tránsito

## 10. Métricas de Éxito

### 10.1 Técnicas
- Tiempo de procesamiento < 5 minutos
- Disponibilidad 99.9%
- Latencia de consultas < 2 segundos

### 10.2 Negocio
- Adopción por equipos de salud
- Reducción en tiempo de análisis
- Mejora en toma de decisiones

## 11. Conclusiones

El data warehouse de defunciones COVID-19 representa una herramienta fundamental para el análisis epidemiológico en Chile. La implementación actual demuestra la viabilidad técnica y el valor analítico del proyecto, sentando las bases para expansiones futuras.

### Fortalezas:
- Datos oficiales y confiables
- Proceso ETL eficiente
- Modelo escalable

### Oportunidades:
- Integración con datos de vacunación
- Análisis predictivos
- Expansión regional

## 12. Recomendaciones

1. **Corto Plazo**: Migrar a base de datos relacional
2. **Mediano Plazo**: Implementar herramientas de visualización
3. **Largo Plazo**: Desarrollar capacidades predictivas

## Anexos

### A. Diccionario de Datos Completo
[Disponible en README.md]

### B. Scripts de Transformación
[Código fuente en main.py]

### C. Ejemplos de Consultas
```sql
-- Top regiones afectadas
SELECT nombre_region, COUNT(*) as defunciones
FROM fact_defunciones_covid
GROUP BY nombre_region
ORDER BY defunciones DESC;

-- Evolución mensual
SELECT año, mes, COUNT(*) as casos
FROM fact_defunciones_covid f
JOIN dim_tiempo t ON f.fecha_id = t.fecha_id
GROUP BY año, mes
ORDER BY año, mes;
```

---
**Documento preparado por**: Sebastián Bravo  
**Fecha**: Julio 2025  
**Versión**: 1.0
