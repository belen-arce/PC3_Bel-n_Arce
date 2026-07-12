# ==============================================================================
# Proyecto: Ollas comunes y condiciones de vida con ENAHO 2024
# Script: 01_integrar_modulos_enaho.R
# Autora: Belén Arce
#
# Objetivo:
# Integrar los módulos 100, 200 y 613 de la ENAHO 2024 para construir una
# base que reúna información de vivienda, integrantes del hogar y acceso
# a alimentos de olla común.
#
# Decisión metodológica:
# El módulo 200 contiene una fila por persona, mientras que los módulos 100
# y 613 contienen información del hogar. Por ello, la base integrada queda
# a nivel de persona y las características del hogar se repiten para cada
# integrante. El módulo 613 se resume previamente a nivel de hogar.
#
# Llaves de integración:
# conglome, vivienda y hogar.
#
# Producto:
# Base integrada guardada en formato Parquet para los siguientes scripts.
#
# Fecha de creación: 21-06-2026
# ==============================================================================

library(tidyverse)
library(janitor)
library(arrow)

# ------------------------------------------------------------------------------
# 1. Cargar los módulos originales de la ENAHO 2024
# ------------------------------------------------------------------------------

# Módulo 100: características de la vivienda y del hogar.
# Nivel de análisis: hogar.
modulo_100 <- suppressWarnings(
  read_csv(
    "datos/crudos/Enaho01-2024-100.csv",
    locale = locale(encoding = "Latin1"),
    show_col_types = FALSE
  )
) %>%
  clean_names()

# Módulo 200: características de cada integrante del hogar.
# Nivel de análisis: persona.
modulo_200 <- read_csv(
  "datos/crudos/Enaho01-2024-200.csv",
  locale = locale(encoding = "Latin1"),
  show_col_types = FALSE
) %>%
  clean_names()

# Módulo 613: acceso del hogar a alimentos de olla común.
# Nivel de análisis utilizado: hogar.
modulo_613 <- read_csv(
  "datos/crudos/Enaho01-2024-613.csv",
  locale = locale(encoding = "Latin1"),
  show_col_types = FALSE
) %>%
  clean_names()

# Verificar que los problemas de lectura del módulo 100 no afecten las variables utilizadas en este proyecto.
variables_utilizadas_100 <- c(
  "anio", "ano", "a_o", "mes",
  "conglome", "vivienda", "hogar",
  "ubigeo", "dominio", "estrato",
  "p101", "p102", "p103", "p104",
  "p110", "p111a", "p1121", "p1144"
)

variables_con_problemas_100 <- names(modulo_100)[
  unique(problems(modulo_100)$col)
]

stopifnot(
  length(
    intersect(variables_utilizadas_100, variables_con_problemas_100)
  ) == 0
)

# ------------------------------------------------------------------------------
# 2. Inspección inicial
# ------------------------------------------------------------------------------

dim(modulo_100)
dim(modulo_200)
dim(modulo_613)

names(modulo_100)
names(modulo_200)
names(modulo_613)

# ------------------------------------------------------------------------------
# 3. Llaves de integración
# ------------------------------------------------------------------------------

# Llave que identifica de manera conjunta a cada hogar.
llave_hogar <- c("conglome", "vivienda", "hogar")

# Detener el procesamiento si alguna llave no está presente.
# Esto evita realizar integraciones incompletas o incorrectas.
stopifnot(
  all(llave_hogar %in% names(modulo_100)),
  all(llave_hogar %in% names(modulo_200)),
  all(llave_hogar %in% names(modulo_613))
)

# ------------------------------------------------------------------------------
# 4. Selección de variables del módulo 100: vivienda y hogar
# ------------------------------------------------------------------------------

hogar_100 <- modulo_100 %>%
  select(
    any_of(c(
      "anio", "ano", "a_o", "mes",
      "conglome", "vivienda", "hogar",
      "ubigeo", "dominio", "estrato",
      "p101",   # tipo de vivienda
      "p102",   # material de paredes
      "p103",   # material de pisos
      "p104",   # número de habitaciones
      "p110",   # procedencia del agua
      "p111a",  # servicio higiénico
      "p1121",  # electricidad
      "p1144"   # internet
    ))
  )

# ------------------------------------------------------------------------------
# 5. Selección de variables del módulo 200: miembros del hogar
# ------------------------------------------------------------------------------

personas_200 <- modulo_200 %>%
  select(
    any_of(c(
      "conglome", "vivienda", "hogar", "codperso",
      "p203",    # parentesco con jefe/a del hogar
      "p204",    # miembro del hogar
      "p205",    # residente habitual
      "p207",    # sexo
      "p208a"    # edad
    ))
  )

# ------------------------------------------------------------------------------
# 6. Preparar módulo 613: olla común
# ------------------------------------------------------------------------------

# p613a = existencia de olla común en la zona
# p613b = hogar obtuvo/compró/recibió alimentos de olla común

num <- function(x) suppressWarnings(as.numeric(x))

# El módulo 613 puede contener más de un registro por hogar.
# Se resume a una sola fila por hogar para evitar duplicaciones al integrarlo con el módulo 200, cuya unidad de análisis es la persona.

olla_613_hogar <- modulo_613 %>%
  group_by(across(all_of(llave_hogar))) %>%
  summarise(
    # Cantidad de registros originales encontrados para cada hogar.
    registros_modulo_613 = n(),
    
    # Se considera que existió una olla común si aparece al menos una respuesta afirmativa.
    existe_olla_zona_num = case_when(
      any(num(p613a) == 1, na.rm = TRUE) ~ 1,
      any(num(p613a) == 2, na.rm = TRUE) ~ 0,
      TRUE ~ NA_real_
    ),
    
    # Se considera que el hogar accedió si registra al menos una respuesta afirmativa.
    # Cuando no existió una olla común en la zona, el acceso se clasifica como no.
    obtuvo_alimentos_olla_num = case_when(
      any(num(p613b) == 1, na.rm = TRUE) ~ 1,
      any(num(p613b) == 2, na.rm = TRUE) ~ 0,
      any(num(p613a) == 2, na.rm = TRUE) ~ 0,
      TRUE ~ NA_real_
    ),
    
    .groups = "drop"
  ) %>%
  mutate(
    existencia_olla_zona = case_when(
      existe_olla_zona_num == 1 ~ "Sí existió olla común en la zona",
      existe_olla_zona_num == 0 ~ "No existió olla común en la zona",
      TRUE ~ "Sin información"
    ),
    
    acceso_olla_comun = case_when(
      obtuvo_alimentos_olla_num == 1 ~ "Sí obtuvo alimentos de olla común",
      obtuvo_alimentos_olla_num == 0 ~ "No obtuvo alimentos de olla común",
      TRUE ~ "Sin información"
    )
  )
# ------------------------------------------------------------------------------
# 7. Integrar los módulos
# ------------------------------------------------------------------------------

# El módulo 200 se utiliza como base porque contiene una fila por persona.
# Los left_join conservan a todos sus registros y añaden las características del hogar y la información sobre ollas comunes mediante la llave del hogar.

base_integrada <- personas_200 %>%
  left_join(hogar_100, by = llave_hogar) %>%
  left_join(olla_613_hogar, by = llave_hogar)

# Verificar que la integración no haya aumentado el número de personas.
# Un aumento indicaría que alguna tabla del hogar contiene llaves duplicadas.
stopifnot(nrow(base_integrada) == nrow(personas_200))

# ------------------------------------------------------------------------------
# 8. Diagnóstico de la base integrada
# ------------------------------------------------------------------------------

# Revisar el número de filas y columnas y la estructura de las variables.
dim(base_integrada)
glimpse(base_integrada)

# ------------------------------------------------------------------------------
# 9. Guardar la base integrada
# ------------------------------------------------------------------------------

# La base final conserva una fila por persona e incorpora características del hogar y su acceso a alimentos de olla común.

ruta_base_integrada <- 
  "datos/procesados/enaho_ollas_comunes_base_integrada.parquet"

write_parquet(
  base_integrada,
  ruta_base_integrada
)
