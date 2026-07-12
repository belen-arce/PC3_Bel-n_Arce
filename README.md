# Procesamiento de datos sobre ollas comunes y condiciones de vida con ENAHO 2024

## Autora

Belén Arce

## Encuesta

Encuesta Nacional de Hogares 2024, elaborada por el Instituto Nacional de Estadística e Informática (INEI).

## Módulos utilizados

- Módulo 100: Características de la vivienda y del hogar.
- Módulo 200: Características de los miembros del hogar.
- Módulo 613: Beneficiarios de instituciones sin fines de lucro: olla común.

## Unidad de análisis

La unidad principal de análisis es el hogar. El módulo 200, que contiene información a nivel de persona, se utiliza de manera complementaria para describir características de los integrantes del hogar, como sexo y edad.

## Propósito del proyecto

Este repositorio demuestra la aplicación articulada de las seis dimensiones del procesamiento de datos cuantitativos: extraer, gestionar, acondicionar, explorar, clasificar y documentar.

El proyecto utiliza microdatos de la ENAHO 2024 para integrar información sobre vivienda, miembros del hogar y acceso a alimentos provenientes de ollas comunes. El objetivo no es realizar un análisis sustantivo ni construir una medida oficial de pobreza, sino desarrollar un flujo de procesamiento reproducible, documentado y trazable en R.

## Estructura del repositorio

```text
PC3_Belén_Arce/
├── datos/
│   ├── crudos/
│   └── procesados/
├── docs/
├── outputs/
│   ├── acondicionar/
│   ├── explorar/
│   ├── clasificar/
│   └── documentar/
├── scripts/
│   ├── 00_setup_proyecto.R
│   ├── 01_integrar_modulos_enaho.R
│   ├── 02_acondicionar_enaho.R
│   ├── 03_explorar_enaho.R
│   ├── 04_clasificar_enaho.R
│   └── 05_documentar_enaho.R
├── .gitignore
├── renv.lock
├── .Rprofile
└── PC3_Belén_Arce.Rproj
```

## Descripción de carpetas
datos/crudos/: contiene los archivos originales descargados del INEI, sin modificaciones.
datos/procesados/: contiene las bases integradas, acondicionadas y clasificadas generadas por los scripts.
docs/: almacena documentación técnica de la ENAHO, como diccionarios, cuestionarios y fichas metodológicas.
outputs/acondicionar/: contiene el reporte y el gráfico de valores perdidos.
outputs/explorar/: contiene las tablas y gráficos del análisis exploratorio univariado y bivariado.
outputs/clasificar/: contiene los reportes y el gráfico de las variables analíticas construidas.
outputs/documentar/: contiene el codebook de la base final y la información del entorno de R.
scripts/: contiene los scripts numerados según su orden de ejecución.

## Scripts del proyecto

Los scripts deben ejecutarse en el siguiente orden:

1. `scripts/00_setup_proyecto.R`: crea la estructura inicial de carpetas, configura `.gitignore` y prepara el entorno reproducible con `renv`.

2. `scripts/01_integrar_modulos_enaho.R`: carga los módulos 100, 200 y 613 de la ENAHO 2024, verifica las llaves de unión, resume el módulo de olla común a nivel de hogar e integra las bases.

3. `scripts/02_acondicionar_enaho.R`: selecciona y renombra las variables de interés, crea variables iniciales y genera el diagnóstico de valores perdidos.

4. `scripts/03_explorar_enaho.R`: construye bases de hogares y personas, realiza la exploración univariada y bivariada, y exporta las tablas y gráficos correspondientes.

5. `scripts/04_clasificar_enaho.R`: crea indicadores de condiciones materiales, un índice simple de vulnerabilidad y una tipología que combina vulnerabilidad y acceso a olla común.

6. `scripts/05_documentar_enaho.R`: genera el codebook de la base clasificada y registra la información del entorno de R mediante `sessionInfo()`.

### Orden de ejecución

```r
source("scripts/01_integrar_modulos_enaho.R")
source("scripts/02_acondicionar_enaho.R")
source("scripts/03_explorar_enaho.R")
source("scripts/04_clasificar_enaho.R")
source("scripts/05_documentar_enaho.R")
```

## 1. EXTRAER

Los datos utilizados provienen de la Encuesta Nacional de Hogares 2024 del Instituto Nacional de Estadística e Informática.

Se trabajó con los siguientes archivos:

- `Enaho01-2024-100.csv`: características de la vivienda y del hogar.
- `Enaho01-2024-200.csv`: características de los miembros del hogar.
- `Enaho01-2024-613.csv`: información sobre ollas comunes.

Los archivos fueron descargados desde el portal de microdatos del INEI y conservados sin modificaciones en `datos/crudos/`. Para interpretar las variables se consultaron el diccionario de datos, los cuestionarios y la ficha técnica de la ENAHO 2024.

### Instrucciones para obtener los datos

1. Ingresar al portal de microdatos del INEI.
2. Seleccionar la Encuesta Nacional de Hogares.
3. Elegir el año 2024.
4. Descargar los módulos de vivienda y hogar, miembros del hogar y olla común.
5. Colocar los archivos CSV en la carpeta `datos/crudos/` conservando sus nombres originales.

Los datos originales no se modifican directamente. Todas las transformaciones se realizan mediante scripts y se guardan en `datos/procesados/`.

## 2. GESTIONAR

El proyecto fue desarrollado como un proyecto de RStudio y mantiene una estructura de carpetas que separa los datos originales, las bases procesadas, los scripts, los documentos técnicos y los outputs generados.

Los scripts están numerados según su orden de ejecución para que el flujo pueda seguirse desde la carga de los módulos originales hasta la documentación de la base final.

### Gestión de paquetes

El proyecto utiliza principalmente los siguientes paquetes de R:

- `tidyverse`: manipulación, recodificación y exportación de datos.
- `arrow`: lectura y escritura de bases en formato Parquet.
- `janitor`: normalización de nombres de variables.
- `naniar`: diagnóstico y visualización de valores perdidos.
- `renv`: registro del entorno de paquetes del proyecto.

El archivo `renv.lock` registra las versiones de los paquetes utilizadas. Para restaurar el entorno en otra computadora se debe ejecutar:

```r
renv::restore()
```

### Control de versiones

El proyecto utiliza Git y GitHub para registrar progresivamente los cambios realizados en los scripts, los outputs y la documentación.

Los commits emplean mensajes descriptivos para identificar etapas como la integración de módulos, el acondicionamiento, la exploración, la clasificación, la corrección de variables y la reorganización de outputs.

El archivo .gitignore evita subir archivos temporales, bases procesadas pesadas y otros elementos que no son necesarios para reproducir el flujo. Los datos originales pueden descargarse nuevamente siguiendo las instrucciones de la sección EXTRAER.

### Reproducibilidad y trazabilidad

La combinación de scripts numerados, rutas relativas, renv.lock, outputs exportados e historial de commits permite seguir el proceso desde los datos originales hasta la base final y sus productos.

## 3. ACONDICIONAR

Los módulos 100, 200 y 613 se cargaron desde los archivos originales y sus nombres de variables se normalizaron para facilitar el procesamiento en R.

La integración se realizó mediante las llaves:

- `conglome`
- `vivienda`
- `hogar`

El módulo 200 contiene información a nivel de persona. Los módulos 100 y 613 contienen principalmente información a nivel de hogar. Para evitar la multiplicación de registros durante la unión, el módulo 613 fue resumido previamente a nivel de hogar.

Después de integrar los módulos, se seleccionaron y renombraron variables relacionadas con:

- ubicación y área de residencia
- características materiales de la vivienda
- acceso a agua, saneamiento, electricidad e internet
- sexo y edad de los miembros del hogar
- existencia de ollas comunes en la zona
- acceso del hogar a alimentos de olla común

### Tratamiento de valores perdidos

Los valores perdidos se conservaron como `NA` cuando no existía información suficiente para asignar una categoría válida. No se realizó imputación estadística, porque el propósito del proyecto es documentar el procesamiento de los datos y no estimar valores ausentes.

Para las variables categóricas se utilizó la categoría `Sin información` cuando era necesario distinguir los casos sin respuesta. Sin embargo, estos casos fueron excluidos del denominador de las tablas y gráficos que presentan porcentajes de respuestas válidas.

Para construir el índice simple de vulnerabilidad se exigió contar con información válida en al menos tres de los cuatro indicadores materiales utilizados. Cuando no se cumplió este criterio, el índice se mantuvo como valor perdido.

### Outputs generados

El script `scripts/02_acondicionar_enaho.R` genera:

- `outputs/acondicionar/reporte_nas_ollas_comunes.csv`: porcentaje de valores perdidos por variable.
- `outputs/acondicionar/grafico_nas_ollas_comunes.png`: representación gráfica de los valores perdidos.
- `datos/procesados/enaho_ollas_comunes_base_acondicionada.parquet`: base seleccionada, renombrada y acondicionada.

## 4. EXPLORAR

La exploración se realizó mediante estadísticas descriptivas univariadas y cruces bivariados. Para respetar el nivel de medición de las variables, se construyeron dos bases de trabajo:

- `base_hogares`: contiene un registro por hogar y se utiliza para analizar área de residencia, características de la vivienda y acceso a alimentos de olla común.
- `base_personas`: conserva un registro por integrante del hogar y se utiliza para describir sexo y grupos de edad.

El acceso a olla común es una característica del hogar. Por ello, cuando se cruza con sexo o edad, el valor del hogar se replica para sus integrantes. Estos cruces permiten describir las características de las personas que viven en hogares con o sin acceso, pero no significan que cada persona haya recibido alimentos individualmente.

Los porcentajes relacionados con acceso a olla común se calcularon únicamente entre respuestas válidas. Los casos clasificados como `Sin información` fueron excluidos del denominador para evitar que alteraran las proporciones.

### Exploración univariada

Se elaboraron distribuciones de frecuencias y porcentajes para:

- acceso del hogar a alimentos de olla común;
- área de residencia;
- sexo de los integrantes;
- grupo de edad.

### Exploración bivariada

Se analizó el acceso a alimentos de olla común según:

- área de residencia;
- sexo de los integrantes del hogar;
- grupo de edad.

Estos cruces son descriptivos y no buscan demostrar relaciones causales.

### Gráficos generados

- `grafico_eda_acceso_olla.png`: muestra la distribución porcentual de hogares que obtuvieron o no alimentos de una olla común.
- `grafico_eda_area_residencia.png`: presenta la distribución de los hogares según área urbana o rural.
- `grafico_eda_olla_por_area.png`: compara el porcentaje de hogares con y sin acceso a olla común dentro de cada área de residencia.
- `grafico_eda_olla_por_grupo_edad.png`: compara la composición por grupos de edad de las personas que viven en hogares con y sin acceso a olla común.

### Outputs generados

Las tablas y gráficos se encuentran en `outputs/explorar/`.

Las tablas univariadas son:

- `eda_univariado_acceso_olla.csv`
- `eda_univariado_area_residencia.csv`
- `eda_univariado_sexo.csv`
- `eda_univariado_grupo_edad.csv`

Las tablas bivariadas son:

- `eda_bivariado_olla_por_area.csv`
- `eda_bivariado_olla_por_sexo.csv`
- `eda_bivariado_olla_por_grupo_edad.csv`

## 5. CLASIFICAR

La clasificación transformó variables originales de la ENAHO en indicadores analíticos más fáciles de interpretar. Las decisiones se basaron en el diccionario de variables de la encuesta y quedaron documentadas en el script y en el codebook.

### Indicadores materiales creados

Se construyeron cuatro variables dicotómicas a nivel de hogar:

- `piso_tierra`: toma el valor 1 cuando el material predominante del piso es tierra y 0 para otros materiales válidos.
- `agua_no_red_publica`: toma el valor 1 cuando el agua no procede de una red pública dentro de la vivienda o del edificio.
- `saneamiento_no_red_publica`: toma el valor 1 cuando el servicio higiénico no está conectado a una red pública de desagüe.
- `sin_internet`: toma el valor 1 cuando el hogar no registra conexión fija o móvil a internet.

En todos los indicadores, los casos sin información suficiente se conservaron como valores perdidos.

### Índice simple de vulnerabilidad

El `indice_vulnerabilidad_simple` corresponde a la suma de los cuatro indicadores materiales. Su rango va de 0 a 4:

- 0 indica ausencia de las privaciones consideradas.
- 4 indica presencia de las cuatro privaciones.

El índice solo se calculó cuando el hogar tenía información válida en al menos tres de los cuatro indicadores. Esta medida es exploratoria y no representa una medición oficial de pobreza o vulnerabilidad.

A partir del índice se creó `nivel_vulnerabilidad`:

- `Baja`: 0 o 1 privación.
- `Media`: 2 privaciones.
- `Alta`: 3 o 4 privaciones.

### Clasificación del acceso a olla común

La variable `acceso_olla_clasificado` resume si el hogar obtuvo, compró o recibió alimentos de una olla común:

- `Accedió a olla común`.
- `No accedió a olla común`.
- `Sin información`.

Los casos sin información se excluyeron de los reportes porcentuales.

### Tipología construida

La variable `tipologia_olla_vulnerabilidad` combina el acceso a olla común con el nivel de vulnerabilidad:

- Accedió a olla común y vulnerabilidad alta.
- Accedió a olla común y vulnerabilidad baja o media.
- No accedió a olla común y vulnerabilidad alta.
- No accedió a olla común y vulnerabilidad baja o media.

La tipología permite mostrar cómo se combinan ambas dimensiones, sin atribuir causalidad ni asumir que el acceso a una olla común depende exclusivamente de las condiciones materiales medidas.

### Outputs generados

El script `scripts/04_clasificar_enaho.R` genera:

- `outputs/clasificar/reporte_clasificacion_dummies.csv`: porcentajes de hogares que presentan cada privación material.
- `outputs/clasificar/reporte_clasificacion_nivel_vulnerabilidad.csv`: distribución de hogares según nivel de vulnerabilidad.
- `outputs/clasificar/reporte_clasificacion_tipologia_olla_vulnerabilidad.csv`: distribución de la tipología construida.
- `outputs/clasificar/grafico_clasificacion_tipologia_olla_vulnerabilidad.png`: representación gráfica de la tipología.
- `datos/procesados/enaho_ollas_comunes_base_clasificada.parquet`: base final con las variables analíticas creadas.

## 6. DOCUMENTAR

La documentación del proyecto se desarrolló en tres niveles complementarios:

1. Los scripts contienen encabezados, secciones numeradas y comentarios que explican el propósito de cada etapa y las decisiones de procesamiento.
2. El README funciona como informe metodológico y describe las seis dimensiones del flujo de trabajo.
3. El codebook reúne el significado, origen, unidad de análisis y codificación de las variables de la base final.

### Codebook

El script `scripts/05_documentar_enaho.R` genera:

- `outputs/documentar/codebook_base_clasificada.csv`

El codebook incluye, para cada variable:

- nombre
- origen
- unidad de análisis
- descripción
- codificación o forma de derivación
- tipo de dato en R
- número de casos válidos y perdidos
- porcentaje de valores perdidos
- número de valores únicos
- ejemplos de valores

Este archivo permite comprender tanto las variables originales de la ENAHO como las variables derivadas creadas durante el acondicionamiento y la clasificación.

### Entorno de trabajo

El mismo script genera:

- `outputs/documentar/session_info.txt`

Este archivo registra la versión de R, el sistema operativo y los paquetes cargados durante la ejecución. Junto con `renv.lock`, permite documentar y restaurar el entorno utilizado.

### Coherencia entre documentación y outputs

Cada sección del README indica qué decisiones se tomaron y qué archivos evidencian el trabajo realizado. Los scripts reproducen el proceso, los outputs muestran sus resultados y el codebook describe la base final.
