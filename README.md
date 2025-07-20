# Data Warehouse - Análisis de Defunciones COVID-19 en Chile

## 📋 Descripción del Proyecto

Este proyecto implementa un proceso ETL (Extract, Transform, Load) para analizar las defunciones relacionadas con COVID-19 en Chile, utilizando datos oficiales del DEIS (Departamento de Estadísticas e Información de Salud) del período 1990-2022. El objetivo es construir un data warehouse que permita análisis multidimensional de la mortalidad por COVID-19.

## 🗂️ Estructura del Repositorio

```
Arquitectura-Datos/
│
├── DEFUNCIONES_FUENTE_DEIS_1990_2022_CIFRAS_OFICIALES.csv  # Datos fuente (832 MB)
├── defunciones_covid_filtradas.csv                          # Datos procesados (15.4 MB)
├── main.py                                                   # Script ETL principal
├── .gitattributes                                           # Configuración Git LFS
└── README.md                                                # Este archivo
```

## 📊 Descripción de los Datos

### Archivo Fuente
- **Nombre**: `DEFUNCIONES_FUENTE_DEIS_1990_2022_CIFRAS_OFICIALES.csv`
- **Tamaño**: 832 MB
- **Período**: 1990-2022
- **Fuente**: DEIS - Ministerio de Salud de Chile
- **Formato**: CSV delimitado por punto y coma (;)
- **Encoding**: Latin-1

### Estructura de Datos

El dataset contiene las siguientes columnas principales:

| Campo | Descripción | Tipo |
|-------|-------------|------|
| AÑO | Año de defunción | Numérico |
| FECHA_DEF | Fecha completa de defunción | Fecha |
| SEXO_NOMBRE | Sexo del fallecido | Categórico |
| EDAD_TIPO | Tipo de edad (1=años) | Numérico |
| EDAD_CANT | Cantidad de edad | Numérico |
| COD_COMUNA | Código de comuna | Numérico |
| COMUNA | Nombre de comuna | Texto |
| NOMBRE_REGION | Nombre de región | Texto |
| DIAG1 | Código diagnóstico principal | Texto |
| GLOSA_SUBCATEGORIA_DIAG1 | Descripción del diagnóstico | Texto |
| LUGAR_DEFUNCION | Lugar donde ocurrió la defunción | Categórico |

## 🔄 Proceso ETL

### 1. **Extracción (Extract)**
- Lee el archivo CSV fuente en chunks de 50,000 registros para optimizar memoria
- Maneja encoding Latin-1 para caracteres especiales en español

### 2. **Transformación (Transform)**
- **Filtrado por COVID-19**: Busca registros con palabras clave:
  - 'covid'
  - 'coronavirus'
  - 'sars-cov'
  - 'u07.1' (COVID-19 confirmado)
  - 'u07.2' (COVID-19 sospechoso)
- **Normalización**: Convierte columnas a mayúsculas y elimina espacios
- **Combinación**: Une campos de diagnóstico para búsqueda comprehensiva

### 3. **Carga (Load)**
- Genera archivo filtrado: `defunciones_covid_filtradas.csv`
- Total de registros COVID: 55,060 defunciones

## 📈 Estadísticas Clave

### Distribución Temporal
- **2019**: 1 caso (coronavirus no especificado)
- **2020**: 18,680 defunciones
- **2021**: 22,946 defunciones (año peak)
- **2022**: 13,433 defunciones

### Características Demográficas
- Análisis disponible por:
  - Sexo
  - Edad
  - Región
  - Comuna
  - Lugar de defunción

## 🏗️ Arquitectura del Data Warehouse

### Modelo Dimensional Propuesto

#### Tabla de Hechos: `fact_defunciones_covid`
- fecha_id (FK)
- ubicacion_id (FK)
- persona_id (FK)
- diagnostico_id (FK)
- cantidad_defunciones
- edad_fallecimiento
- lugar_defuncion

#### Dimensiones:

**1. dim_tiempo**
- fecha_id (PK)
- fecha_completa
- año
- mes
- trimestre
- semestre
- dia_semana
- es_fin_semana

**2. dim_ubicacion**
- ubicacion_id (PK)
- codigo_comuna
- nombre_comuna
- nombre_region
- zona_geografica

**3. dim_persona**
- persona_id (PK)
- sexo
- rango_edad
- grupo_etario

**4. dim_diagnostico**
- diagnostico_id (PK)
- codigo_diag
- tipo_covid (confirmado/sospechoso)
- capitulo_diag
- glosa_capitulo
- subcategoria

## 🚀 Uso del Script

### Requisitos
```bash
pip install pandas
```

### Ejecución
```bash
python main.py
```

### Salida del Script
1. Lista de columnas disponibles
2. Total de registros COVID encontrados
3. Top 10 combinaciones más frecuentes (sexo, edad, región)
4. Defunciones por año
5. Principales causas encontradas
6. Archivo CSV filtrado exportado

## 📊 Casos de Uso Analítico

1. **Análisis Temporal**
   - Evolución mensual de defunciones
   - Comparación entre olas pandémicas
   - Estacionalidad

2. **Análisis Geográfico**
   - Tasas de mortalidad por región
   - Mapas de calor por comuna
   - Correlación urbano/rural

3. **Análisis Demográfico**
   - Pirámides poblacionales de mortalidad
   - Análisis por grupos etarios
   - Diferencias por sexo

4. **Análisis de Lugar de Defunción**
   - Hospital vs domicilio
   - Capacidad hospitalaria

## 🔍 Próximos Pasos

1. **Enriquecimiento de Datos**
   - Agregar datos poblacionales para tasas
   - Incluir datos de vacunación
   - Incorporar indicadores socioeconómicos

2. **Implementación DW**
   - Crear schema en base de datos
   - Implementar procesos ETL automatizados
   - Desarrollar cubos OLAP

3. **Visualización**
   - Dashboards interactivos
   - Reportes automatizados
   - Alertas tempranas

## 📝 Notas Técnicas

- Los archivos CSV utilizan Git LFS debido a su tamaño
- El script procesa datos en chunks para optimizar memoria
- Encoding Latin-1 para manejar caracteres especiales del español

## 👥 Autor

Sebastián Bravo (@sebitabravo)

## 📄 Licencia

Este proyecto utiliza datos públicos del Ministerio de Salud de Chile.
