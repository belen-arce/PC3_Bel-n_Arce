# ==============================================================================
# Proyecto: Ollas comunes, vulnerabilidad alimentaria y condiciones de vida usando datos de la ENAHO
# Autora: Belén Arce
# Objetivo: Acondicionar la base integrada de ENAHO para el análisis inicial
# Fecha: 21-06-2026
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. Cargar paquetes
# ------------------------------------------------------------------------------

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
      
      # Características personales
      "p203",   # Relación de parentesco con jefe/a de hogar
      "p204",   # Miembro del hogar
      "p205",   # Residente habitual
      "p207",   # Sexo
      "p208a",  # Edad
      
      # Variables vinculadas a olla común
      "p612n",
      "p613",
      "p613a",
      "p613b",
      "p613c",
      "p613d",
      "p613e",
      
      # Variables de programas sociales
      "p701",
      "p702",
      "p703",
      "p704",
      "p705"
    ))
  )

# ------------------------------------------------------------------------------
# 4. Renombrar variables principales
# ------------------------------------------------------------------------------

base_renombrada <- base_seleccion %>%
  rename(
    parentesco = any_of("p203"),
    miembro_hogar = any_of("p204"),
    residente_habitual = any_of("p205"),
    sexo = any_of("p207"),
    edad = any_of("p208a"),
    
    olla_comun_1 = any_of("p612n"),
    olla_comun_2 = any_of("p613"),
    olla_comun_3 = any_of("p613a"),
    olla_comun_4 = any_of("p613b"),
    olla_comun_5 = any_of("p613c"),
    olla_comun_6 = any_of("p613d"),
    olla_comun_7 = any_of("p613e"),
    
    programa_social_1 = any_of("p701"),
    programa_social_2 = any_of("p702"),
    programa_social_3 = any_of("p703"),
    programa_social_4 = any_of("p704"),
    programa_social_5 = any_of("p705")
  )

# ------------------------------------------------------------------------------
# 5. Crear variables iniciales de análisis
# ------------------------------------------------------------------------------

base_acondicionada <- base_renombrada %>%
  mutate(
    sexo_recodificado = case_when(
      sexo == 1 ~ "Hombre",
      sexo == 2 ~ "Mujer",
      TRUE ~ NA_character_
    ),
    
    grupo_edad = case_when(
      edad < 18 ~ "Menor de 18",
      edad >= 18 & edad < 30 ~ "18 a 29",
      edad >= 30 & edad < 60 ~ "30 a 59",
      edad >= 60 ~ "60 a más",
      TRUE ~ NA_character_
    ),
    
    # Variable exploratoria.
    # Se marca "Accede o registra vínculo con olla común" si alguna variable
    # del módulo de olla común tiene información.
    acceso_olla_comun = if_else(
      if_any(
        starts_with("olla_comun"),
        ~ !is.na(.)
      ),
      "Sí registra información",
      "No registra información"
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

# ------------------------------------------------------------------------------
# 10. Mensaje final
# ------------------------------------------------------------------------------

message("Base acondicionada guardada en datos/procesados/enaho_ollas_comunes_base_acondicionada.parquet")