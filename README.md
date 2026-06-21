# Ollas comunes, vulnerabilidad alimentaria y condiciones de vida usando datos de la ENAHO

## Descripción del proyecto

Este repositorio contiene la estructura inicial de un proyecto de investigación cuantitativa elaborado en R a partir de datos de la Encuesta Nacional de Hogares (ENAHO). El proyecto busca organizar, integrar y acondicionar módulos de la ENAHO para analizar la relación entre ollas comunes, vulnerabilidad alimentaria y condiciones de vida en los hogares peruanos.

El repositorio fue creado como parte de la PC3 del Taller de Procesamiento de Datos. Su objetivo principal es mostrar una estructura reproducible de trabajo, con carpetas ordenadas, scripts documentados, control de versiones mediante Git y GitHub, y gestión del entorno de paquetes mediante `renv`.

## Pregunta Central

¿Cómo se relaciona el acceso a ollas comunes con la vulnerabilidad alimentaria y las condiciones de vida de los hogares peruanos?

## Fuente de datos

Encuesta Nacional de Hogares (ENAHO) - Instituto Nacional de Estadística e Informática (INEI).

Para el análisis se consideran módulos vinculados con características del hogar, características de las personas, condiciones de vida, programas sociales y acceso a formas de apoyo alimentario.

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
