import pandas as pd

# Ruta del archivo CSV
ruta = 'DEFUNCIONES_FUENTE_DEIS_1990_2022_CIFRAS_OFICIALES.csv'

# Palabras clave asociadas a COVID
keywords = ['covid', 'coronavirus', 'sars-cov', 'u07.1', 'u07.2']

# Tamaño de los fragmentos (chunks)
chunk_size = 50000
resultados = []

for chunk in pd.read_csv(ruta, sep=';', encoding='latin1', chunksize=chunk_size, low_memory=False):
    # Normalizar columnas
    chunk.columns = [str(c).strip().upper() for c in chunk.columns]

    # Detectar columnas que podrían contener diagnóstico
    columnas_causa = [c for c in chunk.columns if 'DIAG' in c or 'GLOSA' in c or 'CATEGORIA' in c]

    # Crear una columna con todas las causas unidas
    causas_combinadas = chunk[columnas_causa].astype(str).apply(lambda row: ' '.join(row.values).lower(), axis=1)

    # Buscar palabras clave de COVID
    filtro = causas_combinadas.str.contains('|'.join(keywords))

    # Filtrar los datos que contienen COVID
    df_covid = chunk[filtro]

    # Guardar fragmento
    resultados.append(df_covid)

# Unir todos los fragmentos en un solo DataFrame
df_final = pd.concat(resultados, ignore_index=True)

# Mostrar columnas disponibles
print("\n📋 Columnas disponibles:")
print(df_final.columns.tolist())

# Total de registros encontrados
print(f"\n✅ Total registros relacionados con COVID: {len(df_final)}")

# Top 10 combinaciones sexo + edad + región
try:
    resumen = df_final[['SEXO_NOMBRE', 'EDAD_CANT', 'NOMBRE_REGION']].value_counts().head(10)
    print("\n📊 Top 10 combinaciones más frecuentes (sexo, edad, región):")
    print(resumen)
except KeyError as e:
    print(f"\n⚠️ No se pudieron generar los top 10: {e}")

# Defunciones por año
try:
    print("\n📈 Defunciones por año:")
    print(df_final['AÑO'].value_counts().sort_index())
except KeyError:
    print("\n⚠️ No se encontró la columna 'AÑO'")

# Causas más frecuentes
try:
    print("\n💀 Principales causas encontradas (glosa subcategoría):")
    print(df_final['GLOSA_SUBCATEGORIA_DIAG1'].value_counts().head(10))
except KeyError:
    print("\n⚠️ No se encontró 'GLOSA_SUBCATEGORIA_DIAG1'")

# Guardar CSV final
df_final.to_csv('defunciones_covid_filtradas.csv', index=False, encoding='utf-8')
print("\n💾 Archivo exportado: defunciones_covid_filtradas.csv")
# Fin del script
