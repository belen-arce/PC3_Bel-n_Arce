# Ollas comunes, vulnerabilidad alimentaria y condiciones de vida usando datos de la ENAHO

## Descripción del proyecto

Este repositorio contiene la estructura inicial de un proyecto de investigación cuantitativa elaborado en R a partir de datos de la Encuesta Nacional de Hogares (ENAHO). El proyecto busca organizar, integrar y acondicionar módulos de la ENAHO para analizar la relación entre ollas comunes, vulnerabilidad alimentaria y condiciones de vida en los hogares peruanos.

El repositorio fue creado como parte de la PC3 del Taller de Procesamiento de Datos. Su objetivo principal es mostrar una estructura reproducible de trabajo, con carpetas ordenadas, scripts documentados, control de versiones mediante Git y GitHub, y gestión del entorno de paquetes mediante `renv`.

## Pregunta Central

¿Cómo se relaciona el acceso a ollas comunes con la vulnerabilidad alimentaria y las condiciones de vida de los hogares peruanos?

## Fuente de datos

La fuente principal del proyecto es la Encuesta Nacional de Hogares (ENAHO), producida por el Instituto Nacional de Estadística e Informática (INEI).

## Estructura del repositorio

```Text
PC3_Belén_Arce/
├── datos/
│   ├── crudos/
│   └── procesados/
├── docs/
├── outputs/
│   ├── graficos/
│   └── tablas/
├── scripts/
│   └── 00_setup_proyecto.R
├── .gitignore
├── renv.lock
├── .Rprofile
└── PC3_Belén_Arce.Rproj
```

## Descripción de carpetas

* `datos/crudos/`: almacena los archivos originales descargados de la ENAHO. Estos archivos no deben modificarse directamente.
* `datos/procesados/`: almacena las bases integradas o acondicionadas generadas mediante scripts.
* `docs/`: almacena documentación técnica, diccionarios de variables, fichas metodológicas u otros materiales de apoyo.
* `outputs/graficos/`: almacena gráficos producidos durante el análisis.
* `outputs/tablas/`: almacena tablas o reportes generados a partir del procesamiento.
* `scripts/`: almacena los scripts de R numerados según el orden de ejecución.

## Scripts del proyecto

 `00_setup_proyecto.R`: crea la estructura de carpetas, configura `.gitignore`, instala o verifica paquetes necesarios, activa `renv` y deja documentado el procedimiento para enlazar el proyecto local con Git y GitHub.


## Paquetes principales

El proyecto utiliza los siguientes paquetes de R:

* `tidyverse`
* `rio`
* `haven`
* `arrow`
* `janitor`
* `naniar`
* `renv`
* `usethis`
* `gitcreds`

## Control de versiones

El proyecto utiliza Git para registrar cambios progresivos en la estructura, los scripts y la documentación. El repositorio será enlazado con GitHub para asegurar trazabilidad y acceso público.

## PC4

Para la PC4 se continuó el flujo de trabajo iniciado en la PC3, usando módulos de la ENAHO 2024 vinculados con características de vivienda y hogar, características de los miembros del hogar y el módulo de olla común.

### Scripts actualizados

- `scripts/01_integrar_modulos_enaho.R`: carga los módulos 100, 200 y 613 de la ENAHO 2024, los integra mediante llaves de hogar y guarda una base integrada en `datos/procesados`.
- `scripts/02_acondicionar_enaho.R`: selecciona variables relevantes, renombra variables principales, crea variables iniciales de análisis y genera reportes de valores perdidos.

### Scripts desarrollados

- `scripts/03_explorar_enaho.R`: realiza exploración univariada y bivariada, y exporta tablas y gráficos en las carpetas `outputs/tablas` y `outputs/graficos`.
- `scripts/04_clasificar_enaho.R`: construye variables analíticas de clasificación, incluyendo dummies, un índice simple de vulnerabilidad y una tipología entre registro de olla común y vulnerabilidad.

### Decisiones metodológicas

La base integrada combina información a nivel de persona y hogar. Para evitar duplicaciones en variables del hogar, el módulo de olla común fue resumido a nivel de hogar antes de realizar los cruces. En la exploración se trabajó con una base de personas y una base de hogares, según el tipo de variable analizada.

La clasificación construida no busca medir pobreza de manera oficial, sino crear un índice simple y exploratorio de vulnerabilidad a partir de condiciones materiales del hogar y características personales disponibles en la base.