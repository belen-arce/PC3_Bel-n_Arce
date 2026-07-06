# ==============================================================================
# Proyecto: Ollas comunes
# Script: 01_integrar_modulos_enaho.R
# Autora: Belén Arce
# Objetivo: Cargar módulos CSV de la ENAHO 2024 y realizar merges para construir una base integrada
# Fecha: 21-06-2026
#==============================================================================

library(tidyverse)
library(janitor)
library(arrow)

# ------------------------------------------------------------------------------
# 1. Cargar módulos ENAHO 2024
# ------------------------------------------------------------------------------

modulo_100 <- read_csv(
  "datos/crudos/Enaho01-2024-100.csv",
  locale = locale(encoding = "Latin1"),
  show_col_types = FALSE
) %>%
  clean_names()

modulo_200 <- read_csv(
  "datos/crudos/Enaho01-2024-200.csv",
  locale = locale(encoding = "Latin1"),
  show_col_types = FALSE
) %>%
  clean_names()

modulo_613 <- read_csv(
  "datos/crudos/Enaho01-2024-613.csv",
  locale = locale(encoding = "Latin1"),
  show_col_types = FALSE
) %>%
  clean_names()

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

# Se usan las llaves de hogar porque los módulos 100 y 613 están a nivel hogar.
# El módulo 200 está a nivel persona, pero contiene las mismas llaves de hogar.

llave_hogar <- c("conglome", "vivienda", "hogar")

# Verificamos que las llaves existan en los tres módulos.

llave_hogar %in% names(modulo_100)
llave_hogar %in% names(modulo_200)
llave_hogar %in% names(modulo_613)

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

olla_613_hogar <- modulo_613 %>%
  group_by(across(all_of(llave_hogar))) %>%
  summarise(
    registros_modulo_613 = n(),
    
    existe_olla_zona_num = case_when(
      any(num(p613a) == 1, na.rm = TRUE) ~ 1,
      any(num(p613a) == 2, na.rm = TRUE) ~ 0,
      TRUE ~ NA_real_
    ),
    
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
# 7. Merges entre módulos
# ------------------------------------------------------------------------------

base_integrada <- personas_200 %>%
  left_join(hogar_100, by = llave_hogar) %>%
  left_join(olla_613_hogar, by = llave_hogar)

# ------------------------------------------------------------------------------
# 8. Diagnóstico de la base integrada
# ------------------------------------------------------------------------------

dim(base_integrada)
glimpse(base_integrada)

# ------------------------------------------------------------------------------
# 9. Guardar base procesada
# ------------------------------------------------------------------------------

write_parquet(
  base_integrada,
  "datos/procesados/enaho_ollas_comunes_base_integrada.parquet"
)
