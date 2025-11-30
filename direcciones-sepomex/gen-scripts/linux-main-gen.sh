#!/bin/bash

FILE_TXT='CPdescarga.txt'
SEPOMEX_DIR='sepomex/'
FILE_TSV='colonias.tsv'
PYTHON_SCRIPT='gen-scripts/gen-sql-from-tsv.py'
SQL_DIR='scripts-sql/'

echo Procesando los datos en sucio de $FILE_TXT

# Se comprueba que exista el archivo
if [ -e FILE_TXT ] 
then
    echo No existe el archivo $FILE_TXT
    exit 1
fi

# Recorte de columnas y transformación a TSV
# Se conservarn solo los campos de:
# - d_codigo : col 1
# - d_asenta : col 2
# - D_mnpio  : col 4
# - d_estado : col 5
# Y se reemplaza el | por tabulación (conversion a tsv)

cut -d '|' -f 1,2,4,5 $SEPOMEX_DIR$FILE_TXT | sed 's/|/\t/g' > $SEPOMEX_DIR$FILE_TSV

# Se comprueba si se generó con éxito el archivo
if [ $? -eq 1 ]
then
    echo Falló la generación del archivo $SEPOMEX_DIR$FILE_TSV
    exit 1
else
    echo Se generó con éxito el archivo $SEPOMEX_DIR$FILE_TSV
fi

# Se comprueba que exista el script de python
if [ -e $PYTHON_SCRIPT ] 
then
    echo Se encontró el script $PYTHON_SCRIPT
else
    echo No existe el script $PYTHON_SCRIPT
    exit 1
fi

# Se comprueba si existe el directorio dest de los scripts sql
if [ -d $SQL_DIR ]
then
    echo Se encontró el directorio $SQL_DIR
else
    echo El directorio $SQL_DIR no existe.
    mkdir $SQL_DIR
    echo Se creó el directorio $SQL_DIR
fi

python3 $PYTHON_SCRIPT

if [ $? -eq 1 ]
then
    echo Falló la generación de los scripts SQL
    exit 1
fi
