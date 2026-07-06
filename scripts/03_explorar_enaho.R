# ==============================================================================
# Proyecto: Ollas comunes, vulnerabilidad alimentaria y condiciones de vida usando datos de la ENAHO
# Script: 03_explorar_enaho.R
# Autora: Belén Arce
# Objetivo: Realizar exploración univariada y bivariada de la base acondicionada
# Fecha: 05-07-2026
# ==============================================================================

library(tidyverse)
library(arrow)

# ------------------------------------------------------------------------------
# 1. Cargar base acondicionada
# ------------------------------------------------------------------------------

base_acondicionada <- read_parquet(
  "datos/procesados/enaho_ollas_comunes_base_acondicionada.parquet"
)

# ------------------------------------------------------------------------------
# 2. Crear base a nivel hogar y base a nivel persona
# ------------------------------------------------------------------------------

base_personas <- base_acondicionada

base_hogares <- base_acondicionada %>%
  distinct(conglome, vivienda, hogar, .keep_all = TRUE)

# ------------------------------------------------------------------------------
# 3. Exploración univariada
# ------------------------------------------------------------------------------

tabla_acceso_olla <- base_hogares %>%
  count(acceso_olla_comun) %>%
  mutate(porcentaje = round(n / sum(n) * 100, 2))

write_csv(
  tabla_acceso_olla,
  "outputs/tablas/eda_univariado_acceso_olla.csv"
)

tabla_area <- base_hogares %>%
  count(area_residencia) %>%
  mutate(porcentaje = round(n / sum(n) * 100, 2))

write_csv(
  tabla_area,
  "outputs/tablas/eda_univariado_area_residencia.csv"
)

tabla_sexo <- base_personas %>%
  count(sexo_recodificado) %>%
  mutate(porcentaje = round(n / sum(n) * 100, 2))

write_csv(
  tabla_sexo,
  "outputs/tablas/eda_univariado_sexo.csv"
)

tabla_grupo_edad <- base_personas %>%
  count(grupo_edad) %>%
  mutate(porcentaje = round(n / sum(n) * 100, 2))

write_csv(
  tabla_grupo_edad,
  "outputs/tablas/eda_univariado_grupo_edad.csv"
)

# ------------------------------------------------------------------------------
# 4. Gráficos univariados
# ------------------------------------------------------------------------------

grafico_acceso_olla <- ggplot(tabla_acceso_olla, aes(x = acceso_olla_comun, y = n)) +
  geom_col() +
  labs(
    title = "Hogares según registro de información en módulo de olla común",
    x = "Registro en módulo 613",
    y = "Número de hogares"
  ) +
  theme_minimal()

ggsave(
  filename = "outputs/graficos/grafico_eda_acceso_olla.png",
  plot = grafico_acceso_olla,
  width = 8,
  height = 6,
  bg = "white"
)

grafico_area <- ggplot(tabla_area, aes(x = area_residencia, y = n)) +
  geom_col() +
  labs(
    title = "Hogares según área de residencia",
    x = "Área de residencia",
    y = "Número de hogares"
  ) +
  theme_minimal()

ggsave(
  filename = "outputs/graficos/grafico_eda_area_residencia.png",
  plot = grafico_area,
  width = 8,
  height = 6,
  bg = "white"
)

# ------------------------------------------------------------------------------
# 5. Exploración bivariada
# ------------------------------------------------------------------------------

tabla_olla_area <- base_hogares %>%
  count(area_residencia, acceso_olla_comun) %>%
  group_by(area_residencia) %>%
  mutate(porcentaje = round(n / sum(n) * 100, 2)) %>%
  ungroup()

write_csv(
  tabla_olla_area,
  "outputs/tablas/eda_bivariado_olla_por_area.csv"
)

tabla_olla_sexo <- base_personas %>%
  count(sexo_recodificado, acceso_olla_comun) %>%
  group_by(sexo_recodificado) %>%
  mutate(porcentaje = round(n / sum(n) * 100, 2)) %>%
  ungroup()

write_csv(
  tabla_olla_sexo,
  "outputs/tablas/eda_bivariado_olla_por_sexo.csv"
)

tabla_olla_edad <- base_personas %>%
  count(grupo_edad, acceso_olla_comun) %>%
  group_by(grupo_edad) %>%
  mutate(porcentaje = round(n / sum(n) * 100, 2)) %>%
  ungroup()

write_csv(
  tabla_olla_edad,
  "outputs/tablas/eda_bivariado_olla_por_grupo_edad.csv"
)

# ------------------------------------------------------------------------------
# 6. Gráficos bivariados
# ------------------------------------------------------------------------------

grafico_olla_area <- ggplot(
  tabla_olla_area,
  aes(x = area_residencia, y = porcentaje, fill = acceso_olla_comun)
) +
  geom_col(position = "dodge") +
  labs(
    title = "Registro de olla común según área de residencia",
    x = "Área de residencia",
    y = "Porcentaje",
    fill = "Registro de olla común"
  ) +
  theme_minimal()

ggsave(
  filename = "outputs/graficos/grafico_eda_olla_por_area.png",
  plot = grafico_olla_area,
  width = 8,
  height = 6,
  bg = "white"
)

grafico_olla_edad <- ggplot(
  tabla_olla_edad,
  aes(x = grupo_edad, y = porcentaje, fill = acceso_olla_comun)
) +
  geom_col(position = "dodge") +
  labs(
    title = "Registro de olla común según grupo de edad",
    x = "Grupo de edad",
    y = "Porcentaje",
    fill = "Registro de olla común"
  ) +
  theme_minimal()

ggsave(
  filename = "outputs/graficos/grafico_eda_olla_por_grupo_edad.png",
  plot = grafico_olla_edad,
  width = 8,
  height = 6,
  bg = "white"
)
