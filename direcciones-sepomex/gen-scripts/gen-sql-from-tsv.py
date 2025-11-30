import csv
import sys

# --- CONFIGURACIÓN ---
NOMBRE_ARCHIVO_INPUT = 'sepomex/colonias.tsv'
ARCHIVO_SALIDA_GEO = 'scripts-sql/1_catalogos_base.sql'
ARCHIVO_SALIDA_COL = 'scripts-sql/2_direcciones_colonias.sql'

def limpiar_texto(texto):
    """Escapa comillas simples para SQL Server"""
    if not texto: return ""
    return texto.strip().replace("'", "''")

def generar_archivos():
    print(f"Leyendo archivo {NOMBRE_ARCHIVO_INPUT}...")
    
    registros = []
    
    # 1. Detección de encoding
    encoding = 'utf-8'
    try:
        with open(NOMBRE_ARCHIVO_INPUT, 'r', encoding='utf-8') as f: f.read(500)
    except UnicodeDecodeError:
        encoding = 'latin-1'
        print(" -> Detectado encoding Latin-1")

    try:
        with open(NOMBRE_ARCHIVO_INPUT, 'r', encoding=encoding, newline='') as f:
            # 2. Búsqueda manual de la cabecera
            linea = f.readline()
            while linea:
                # Buscamos la línea que tenga las columnas clave
                if "d_codigo" in linea and "d_estado" in linea:
                    break
                linea = f.readline()
            
            if not linea:
                print("ERROR CRÍTICO: No se encontró la cabecera (d_codigo, d_estado) en el archivo.")
                return

            # 3. Limpieza manual de columnas
            # Quitamos espacios y saltos de linea, y separamos por TAB
            columnas_crudas = linea.strip().split('\t')
            # Limpiamos cada nombre de columna (quita espacios invisibles y comillas)
            nombres_columnas = [c.strip().replace('"', '') for c in columnas_crudas]
            
            print(f" -> Cabecera encontrada y limpia: {nombres_columnas}")

            # 4. Iniciamos el DictReader pasándole las columnas YA limpias
            # Al pasarle 'fieldnames', el lector asume que la siguiente línea ya son datos.
            reader = csv.DictReader(f, fieldnames=nombres_columnas, delimiter='\t')
            
            for row in reader:
                # Validación extra: saltar filas vacías
                if not row.get('d_codigo') or not row.get('d_estado'):
                    continue

                registros.append({
                    'cp': row['d_codigo'],
                    'colonia': row['d_asenta'],
                    'municipio': row['D_mnpio'],
                    'estado': row['d_estado']
                })
                    
    except FileNotFoundError:
        print(f"ERROR: No se encontró el archivo '{NOMBRE_ARCHIVO_INPUT}'")
        return

    print(f" -> Procesados {len(registros)} registros correctamente.")
    
    # ---------------------------------------------------------
    # GENERACIÓN SQL
    # ---------------------------------------------------------
    
    nombres_estados = sorted(list(set(r['estado'] for r in registros)))
    mapa_estados = {nombre: i+1 for i, nombre in enumerate(nombres_estados)}
    
    nombres_municipios = sorted(list(set((r['estado'], r['municipio']) for r in registros)))
    mapa_municipios = {tupla: i+1 for i, tupla in enumerate(nombres_municipios)}

    print("Generando scripts SQL...")

    # --- ARCHIVO 1: ESTADOS Y MUNICIPIOS ---
    with open(ARCHIVO_SALIDA_GEO, 'w', encoding='utf-8') as f:
        f.write("-- Script generado para SQL Server (Origen TSV)\n")
        
        # Estados
        f.write("SET IDENTITY_INSERT CATALOGO.ESTADO ON;\n")
        for estado, id_edo in mapa_estados.items():
            f.write(f"INSERT INTO CATALOGO.ESTADO (estado_id, nombre_estado) VALUES ({id_edo}, '{limpiar_texto(estado)}');\n")
        f.write("SET IDENTITY_INSERT CATALOGO.ESTADO OFF;\nGO\n\n")
        
        # Municipios
        f.write("SET IDENTITY_INSERT CATALOGO.MUNICIPIO ON;\n")
        for (nom_edo, nom_mun), id_mun in mapa_municipios.items():
            id_edo = mapa_estados[nom_edo]
            f.write(f"INSERT INTO CATALOGO.MUNICIPIO (municipio_id, nombre_municipio, estado_id) VALUES ({id_mun}, '{limpiar_texto(nom_mun)}', {id_edo});\n")
        f.write("SET IDENTITY_INSERT CATALOGO.MUNICIPIO OFF;\nGO\n")

    # --- ARCHIVO 2: COLONIAS ---
    with open(ARCHIVO_SALIDA_COL, 'w', encoding='utf-8') as f:
        f.write("-- Carga Masiva de Colonias\nSET NOCOUNT ON;\n")
        
        buffer = []
        for r in registros:
            id_mun = mapa_municipios.get((r['estado'], r['municipio']))
            if id_mun:
                nom_col = limpiar_texto(r['colonia'])
                if not nom_col: nom_col = "Sin Nombre"
                
                valores = f"('{nom_col}', '{r['cp']}', {id_mun})"
                buffer.append(valores)
            
            if len(buffer) >= 1000:
                f.write("INSERT INTO CATALOGO.COLONIA (nombre_colonia, codigo_postal, municipio_id) VALUES \n")
                f.write(",\n".join(buffer) + ";\n")
                buffer = []
        
        if buffer:
            f.write("INSERT INTO CATALOGO.COLONIA (nombre_colonia, codigo_postal, municipio_id) VALUES \n")
            f.write(",\n".join(buffer) + ";\n")
        f.write("\nGO\n")

    print("Archivos SQL generados sin errores.")

if __name__ == '__main__':
    generar_archivos()
