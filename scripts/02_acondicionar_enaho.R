# ==============================================================================
# Proyecto: Ollas comunes, vulnerabilidad alimentaria y condiciones de vida usando datos de la ENAHO
# Autora: Belén Arce
# Objetivo: Acondicionar la base integrada de ENAHO para el análisis inicial
# Fecha: 21-06-2026
# ==============================================================================

library(tidyverse)
library(arrow)
library(janitor)
library(naniar)

# ------------------------------------------------------------------------------
# 1. Cargar base integrada
# ------------------------------------------------------------------------------

base_integrada <- read_parquet(
  "datos/procesados/enaho_ollas_comunes_base_integrada.parquet"
)

# ------------------------------------------------------------------------------
# 2. Inspección inicial
# ------------------------------------------------------------------------------

dim(base_integrada)
names(base_integrada)
glimpse(base_integrada)

# ------------------------------------------------------------------------------
# 3. Seleccionar variables de interés
# ------------------------------------------------------------------------------

base_seleccion <- base_integrada %>%
  select(
    any_of(c(
      # Llaves
      "conglome", "vivienda", "hogar", "codperso",
      
      # Ubicación y características del hogar
      "ubigeo", "dominio", "estrato",
      
      # Características de vivienda y servicios
      "p101",
      "p102",
      "p103",
      "p104",
      "p110",
      "p111a",
      "p1121",
      "p1144",
      
      # Características personales
      "p203",
      "p204",
      "p205",
      "p207",
      "p208a",
      
      # Variables correctas del módulo 613
      "registros_modulo_613",
      "existe_olla_zona_num",
      "obtuvo_alimentos_olla_num",
      "existencia_olla_zona",
      "acceso_olla_comun"
    ))
  )

# ------------------------------------------------------------------------------
# 4. Renombrar variables principales
# ------------------------------------------------------------------------------

base_renombrada <- base_seleccion %>%
  rename(
    tipo_vivienda = any_of("p101"),
    material_paredes = any_of("p102"),
    material_piso = any_of("p103"),
    habitaciones = any_of("p104"),
    procedencia_agua = any_of("p110"),
    servicio_higienico = any_of("p111a"),
    electricidad = any_of("p1121"),
    internet = any_of("p1144"),
    
    parentesco = any_of("p203"),
    miembro_hogar = any_of("p204"),
    residente_habitual = any_of("p205"),
    sexo = any_of("p207"),
    edad = any_of("p208a")
  )

# ------------------------------------------------------------------------------
# 5. Crear variables iniciales de análisis
# ------------------------------------------------------------------------------

base_acondicionada <- base_renombrada %>%
  mutate(
    sexo_recodificado = case_when(
      sexo == 1 ~ "Hombre",
      sexo == 2 ~ "Mujer",
      TRUE ~ "Sin información"
    ),
    
    grupo_edad = case_when(
      edad < 18 ~ "Menor de 18",
      edad >= 18 & edad < 30 ~ "18 a 29",
      edad >= 30 & edad < 60 ~ "30 a 59",
      edad >= 60 ~ "60 a más",
      TRUE ~ "Sin información"
    ),
    
    area_residencia = case_when(
      as.numeric(estrato) <= 5 ~ "Urbana",
      as.numeric(estrato) >= 6 ~ "Rural",
      TRUE ~ "Sin información"
    ),
    
    acceso_olla_comun = replace_na(
      acceso_olla_comun,
      "Sin información"
    ),
    
    existencia_olla_zona = replace_na(
      existencia_olla_zona,
      "Sin información"
    )
  )

# ------------------------------------------------------------------------------
# 6. Diagnóstico de valores perdidos
# ------------------------------------------------------------------------------

reporte_nas <- base_acondicionada %>%
  summarise(across(everything(), ~ round(sum(is.na(.)) / n() * 100, 2))) %>%
  pivot_longer(
    cols = everything(),
    names_to = "variable",
    values_to = "porcentaje_na"
  ) %>%
  arrange(desc(porcentaje_na))

write_csv(
  reporte_nas,
  "outputs/tablas/reporte_nas_ollas_comunes.csv"
)

# ------------------------------------------------------------------------------
# 7. Gráfico de valores perdidos
# ------------------------------------------------------------------------------

grafico_nas <- gg_miss_var(base_acondicionada, show_pct = TRUE) +
  labs(
    title = "Porcentaje de valores perdidos por variable",
    subtitle = "Proyecto ENAHO: ollas comunes y vulnerabilidad alimentaria",
    x = "Variables",
    y = "Porcentaje de valores perdidos"
  ) +
  theme_minimal()

ggsave(
  filename = "outputs/graficos/grafico_nas_ollas_comunes.png",
  plot = grafico_nas,
  width = 8,
  height = 6,
  bg = "white"
)

# ------------------------------------------------------------------------------
# 8. Tablas exploratorias iniciales
# ------------------------------------------------------------------------------

tabla_acceso_olla <- base_acondicionada %>%
  count(acceso_olla_comun) %>%
  mutate(porcentaje = round(n / sum(n) * 100, 2))

write_csv(
  tabla_acceso_olla,
  "outputs/tablas/tabla_acceso_olla_comun.csv"
)

tabla_olla_por_sexo <- base_acondicionada %>%
  count(sexo_recodificado, acceso_olla_comun) %>%
  group_by(sexo_recodificado) %>%
  mutate(porcentaje = round(n / sum(n) * 100, 2)) %>%
  ungroup()

write_csv(
  tabla_olla_por_sexo,
  "outputs/tablas/tabla_olla_comun_por_sexo.csv"
)

# ------------------------------------------------------------------------------
# 9. Guardar base acondicionada
# ------------------------------------------------------------------------------

write_parquet(
  base_acondicionada,
  "datos/procesados/enaho_ollas_comunes_base_acondicionada.parquet"
)
