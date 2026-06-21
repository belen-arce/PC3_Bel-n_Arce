# ==============================================================================
# Proyecto: Ollas comunes, vulnerabilidad alimentaria y condiciones de vida usando datos de la ENAHO
# Autora: Belén Arce
# Objetivo: Cargar módulos de la ENAHO y realizar merges para construir una base integrada
# Fecha: 21-06-2026
# ==============================================================================

# ------------------------------------------------------------------------------
# Cargar paquetes
# ------------------------------------------------------------------------------

library(tidyverse)
library(rio)
library(janitor)
library(arrow)

# ------------------------------------------------------------------------------
# 1. Definir función auxiliar para encontrar archivos
# ------------------------------------------------------------------------------

buscar_modulo <- function(numero_modulo) {
  
  archivos <- list.files(
    path = "datos/crudos",
    pattern = paste0(numero_modulo, ".*\\.sav$"),
    full.names = TRUE,
    ignore.case = TRUE
  )
  
  if (length(archivos) == 0) {
    stop(
      paste0(
        "No se encontró el módulo ", numero_modulo, 
        " en la carpeta datos/crudos. ",
        "Verifica que el archivo .sav esté descargado y colocado allí."
      )
    )
  }
  
  if (length(archivos) > 1) {
    message("Se encontró más de un archivo para el módulo ", numero_modulo, 
            ". Se usará el primero: ", archivos[1])
  }
  
  return(archivos[1])
}

# ------------------------------------------------------------------------------
# 2. Identificar archivos de módulos ENAHO
# ------------------------------------------------------------------------------

# Módulo 100: características de la vivienda y del hogar
archivo_100 <- buscar_modulo("100")

# Módulo 200: características de los miembros del hogar
archivo_200 <- buscar_modulo("200")

# Módulo 613: beneficiarios de instituciones sin fines de lucro / olla común
archivo_613 <- buscar_modulo("613")

# Módulo 700: programas sociales
archivo_700 <- buscar_modulo("700")

# ------------------------------------------------------------------------------
# 3. Cargar módulos
# ------------------------------------------------------------------------------

modulo_100 <- import(archivo_100) %>%
  clean_names()

modulo_200 <- import(archivo_200) %>%
  clean_names()

modulo_613 <- import(archivo_613) %>%
  clean_names()

modulo_700 <- import(archivo_700) %>%
  clean_names()

# ------------------------------------------------------------------------------
# 4. Inspección inicial
# ------------------------------------------------------------------------------

dim(modulo_100)
dim(modulo_200)
dim(modulo_613)
dim(modulo_700)

names(modulo_100)
names(modulo_200)
names(modulo_613)
names(modulo_700)

# ------------------------------------------------------------------------------
# 5. Definir llaves de integración
# ------------------------------------------------------------------------------

# Las llaves de hogar permiten unir bases que tienen información del mismo hogar.
# En ENAHO suelen utilizarse CONGLOME, VIVIENDA y HOGAR.
# Luego de clean_names(), quedan en minúsculas.

llave_hogar <- c("conglome", "vivienda", "hogar")

# ------------------------------------------------------------------------------
# 6. Seleccionar variables mínimas de cada módulo
# ------------------------------------------------------------------------------

# Usamos any_of() para evitar errores si alguna variable no aparece exactamente igual
# en una versión específica de la ENAHO.

hogar_100 <- modulo_100 %>%
  select(
    any_of(c(
      "conglome", "vivienda", "hogar",
      "ubigeo", "dominio", "estrato",
      "p101", "p102", "p103", "p104"
    ))
  )

personas_200 <- modulo_200 %>%
  select(
    any_of(c(
      "conglome", "vivienda", "hogar", "codperso",
      "p203", "p204", "p205", "p207", "p208a"
    ))
  )

olla_613 <- modulo_613 %>%
  select(
    any_of(c(
      "conglome", "vivienda", "hogar",
      "p612n", "p613", "p613a", "p613b", "p613c", "p613d", "p613e"
    ))
  )

programas_700 <- modulo_700 %>%
  select(
    any_of(c(
      "conglome", "vivienda", "hogar",
      "p701", "p702", "p703", "p704", "p705"
    ))
  )

# ------------------------------------------------------------------------------
# 7. Realizar merges entre módulos
# ------------------------------------------------------------------------------

base_hogar_olla <- hogar_100 %>%
  left_join(olla_613, by = llave_hogar)

# Agregamos información de programas sociales.

base_hogar_olla_programas <- base_hogar_olla %>%
  left_join(programas_700, by = llave_hogar)

# Incorporamos características de las personas del hogar.

base_integrada <- personas_200 %>%
  left_join(base_hogar_olla_programas, by = llave_hogar)

# ------------------------------------------------------------------------------
# 8. Diagnóstico de la base integrada
# ------------------------------------------------------------------------------

dim(base_integrada)
names(base_integrada)
glimpse(base_integrada)

# ------------------------------------------------------------------------------
# 9. Guardar base procesada
# ------------------------------------------------------------------------------

write_parquet(
  base_integrada,
  "datos/procesados/enaho_ollas_comunes_base_integrada.parquet"
)

# ------------------------------------------------------------------------------
# 10. Mensaje final
# ------------------------------------------------------------------------------

message("Base integrada guardada en datos/procesados/enaho_ollas_comunes_base_integrada.parquet")