# ==============================================================================
# Proyecto: Ollas comunes, vulnerabilidad alimentaria y condiciones de vida usando datos de la ENAHO
# Script: 03_explorar_enaho.R
# Autora: Belén Arce
# Objetivo: Realizar exploración univariada y bivariada 
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
# 2. Crear bases de trabajo
# ------------------------------------------------------------------------------

base_personas <- base_acondicionada

base_hogares <- base_acondicionada %>%
  distinct(conglome, vivienda, hogar, .keep_all = TRUE)

respuestas_validas_olla <- c(
  "No obtuvo alimentos de olla común",
  "Sí obtuvo alimentos de olla común"
)

base_hogares_olla_valida <- base_hogares %>%
  filter(acceso_olla_comun %in% respuestas_validas_olla)

base_personas_olla_valida <- base_personas %>%
  filter(acceso_olla_comun %in% respuestas_validas_olla)

# ------------------------------------------------------------------------------
# 3. Tablas univariadas
# ------------------------------------------------------------------------------

tabla_acceso_olla <- base_hogares_olla_valida %>%
  count(acceso_olla_comun) %>%
  mutate(porcentaje = round(n / sum(n) * 100, 2))

write_csv(
  tabla_acceso_olla,
  "outputs/tablas/eda_univariado_acceso_olla.csv"
)

tabla_area <- base_hogares %>%
  filter(area_residencia != "Sin información") %>%
  count(area_residencia) %>%
  mutate(porcentaje = round(n / sum(n) * 100, 2))

write_csv(
  tabla_area,
  "outputs/tablas/eda_univariado_area_residencia.csv"
)

tabla_sexo <- base_personas %>%
  filter(sexo_recodificado != "Sin información") %>%
  count(sexo_recodificado) %>%
  mutate(porcentaje = round(n / sum(n) * 100, 2))

write_csv(
  tabla_sexo,
  "outputs/tablas/eda_univariado_sexo.csv"
)

tabla_grupo_edad <- base_personas %>%
  filter(grupo_edad != "Sin información") %>%
  count(grupo_edad) %>%
  mutate(porcentaje = round(n / sum(n) * 100, 2))

write_csv(
  tabla_grupo_edad,
  "outputs/tablas/eda_univariado_grupo_edad.csv"
)

# ------------------------------------------------------------------------------
# 4. Tablas bivariadas
# ------------------------------------------------------------------------------

tabla_olla_area <- base_hogares_olla_valida %>%
  filter(area_residencia != "Sin información") %>%
  count(area_residencia, acceso_olla_comun) %>%
  group_by(area_residencia) %>%
  mutate(porcentaje = round(n / sum(n) * 100, 2)) %>%
  ungroup()

write_csv(
  tabla_olla_area,
  "outputs/tablas/eda_bivariado_olla_por_area.csv"
)

tabla_olla_sexo <- base_personas_olla_valida %>%
  filter(sexo_recodificado != "Sin información") %>%
  count(sexo_recodificado, acceso_olla_comun) %>%
  group_by(sexo_recodificado) %>%
  mutate(porcentaje = round(n / sum(n) * 100, 2)) %>%
  ungroup()

write_csv(
  tabla_olla_sexo,
  "outputs/tablas/eda_bivariado_olla_por_sexo.csv"
)

tabla_olla_edad <- base_personas_olla_valida %>%
  filter(grupo_edad != "Sin información") %>%
  count(grupo_edad, acceso_olla_comun) %>%
  group_by(grupo_edad) %>%
  mutate(porcentaje = round(n / sum(n) * 100, 2)) %>%
  ungroup()

write_csv(
  tabla_olla_edad,
  "outputs/tablas/eda_bivariado_olla_por_grupo_edad.csv"
)

# ------------------------------------------------------------------------------
# 5. Gráficos univariados
# ------------------------------------------------------------------------------

grafico_acceso_olla <- ggplot(
  tabla_acceso_olla,
  aes(x = reorder(acceso_olla_comun, porcentaje), y = porcentaje)
) +
  geom_col() +
  geom_text(aes(label = paste0(porcentaje, "%")), hjust = -0.1, size = 4) +
  coord_flip() +
  labs(
    title = "Hogares según acceso a alimentos de olla común",
    subtitle = "Porcentaje calculado sobre respuestas válidas",
    x = NULL,
    y = "Porcentaje de hogares"
  ) +
  ylim(0, max(tabla_acceso_olla$porcentaje) + 10) +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold"))

ggsave(
  "outputs/graficos/grafico_eda_acceso_olla.png",
  grafico_acceso_olla,
  width = 9,
  height = 6,
  bg = "white"
)

grafico_area <- ggplot(
  tabla_area,
  aes(x = area_residencia, y = porcentaje)
) +
  geom_col() +
  geom_text(aes(label = paste0(porcentaje, "%")), vjust = -0.3, size = 4) +
  labs(
    title = "Hogares según área de residencia",
    x = "Área de residencia",
    y = "Porcentaje de hogares"
  ) +
  ylim(0, max(tabla_area$porcentaje) + 10) +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold"))

ggsave(
  "outputs/graficos/grafico_eda_area_residencia.png",
  grafico_area,
  width = 8,
  height = 6,
  bg = "white"
)

# ------------------------------------------------------------------------------
# 6. Gráficos bivariados
# ------------------------------------------------------------------------------

grafico_olla_area <- ggplot(
  tabla_olla_area,
  aes(x = area_residencia, y = porcentaje, fill = acceso_olla_comun)
) +
  geom_col(position = "dodge") +
  geom_text(
    aes(label = paste0(porcentaje, "%")),
    position = position_dodge(width = 0.9),
    vjust = -0.3,
    size = 3.5
  ) +
  labs(
    title = "Acceso a alimentos de olla común según área de residencia",
    subtitle = "Porcentaje dentro de cada área, usando respuestas válidas",
    x = "Área de residencia",
    y = "Porcentaje",
    fill = "Acceso a olla común"
  ) +
  ylim(0, 105) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "bottom"
  )

ggsave(
  "outputs/graficos/grafico_eda_olla_por_area.png",
  grafico_olla_area,
  width = 9,
  height = 6,
  bg = "white"
)

grafico_olla_edad <- ggplot(
  tabla_olla_edad,
  aes(x = grupo_edad, y = porcentaje, fill = acceso_olla_comun)
) +
  geom_col(position = "dodge") +
  geom_text(
    aes(label = paste0(porcentaje, "%")),
    position = position_dodge(width = 0.9),
    vjust = -0.3,
    size = 3.2
  ) +
  labs(
    title = "Acceso a alimentos de olla común según grupo de edad",
    subtitle = "Porcentaje dentro de cada grupo de edad, usando respuestas válidas",
    x = "Grupo de edad",
    y = "Porcentaje",
    fill = "Acceso a olla común"
  ) +
  ylim(0, 105) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "bottom"
  )

ggsave(
  "outputs/graficos/grafico_eda_olla_por_grupo_edad.png",
  grafico_olla_edad,
  width = 9,
  height = 6,
  bg = "white"
)
