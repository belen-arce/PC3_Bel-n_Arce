# ==============================================================================
# Proyecto: Ollas comunes y condiciones de vida con ENAHO 2024
# Script: 03_explorar_enaho.R
# Autora: Belén Arce
#
# Objetivo:
# Generar tablas y gráficos descriptivos univariados y bivariados a partir
# de la base acondicionada.
#
# Unidades de análisis:
# - Hogar: para acceso a olla común, área de residencia y su cruce.
# - Persona: para sexo, grupo de edad y los cruces con el acceso del hogar.
#
# Decisión metodológica:
# El acceso a olla común es una característica del hogar. En los cruces por
# sexo y edad, esta característica se asigna a cada integrante, por lo que
# los resultados describen personas que viven en hogares con o sin acceso.
#
# Tratamiento de casos sin información:
# Los porcentajes se calculan únicamente con categorías válidas. Los casos
# identificados como "Sin información" se conservan en la base, pero se
# excluyen de los denominadores de las tablas y gráficos correspondientes.
#
# Productos:
# - Tablas descriptivas en formato CSV.
# - Gráficos univariados y bivariados en formato PNG.
#
# Fecha de creación: 05-07-2026
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
# 2. Creación de bases de trabajo
# ------------------------------------------------------------------------------

# Base a nivel de persona. Conserva una fila por integrante del hogar.
base_personas <- base_acondicionada

# Base a nivel de hogar. Se conserva una sola fila por combinación de llaves,
# evitando contar varias veces al mismo hogar en los análisis correspondientes.
base_hogares <- base_acondicionada %>%
  distinct(conglome, vivienda, hogar, .keep_all = TRUE)

# Comprobar que la base de hogares tenga una sola fila por hogar.
stopifnot(
  nrow(base_hogares) ==
    n_distinct(base_hogares$conglome,
               base_hogares$vivienda,
               base_hogares$hogar)
)

# Categorías utilizadas para calcular los porcentajes de acceso.
# "Sin información" se conserva en la base, pero no entra al denominador.
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

# Distribución de hogares según acceso a alimentos de olla común.
tabla_acceso_olla <- base_hogares_olla_valida %>%
  count(acceso_olla_comun) %>%
  mutate(porcentaje = round(n / sum(n) * 100, 1))

write_csv(
  tabla_acceso_olla %>%
    transmute(
      `Acceso a olla común` = acceso_olla_comun,
      Hogares = n,
      `Porcentaje de hogares` = porcentaje
    ),
  "outputs/explorar/eda_univariado_acceso_olla.csv"
)

# Distribución de hogares según área de residencia.
tabla_area <- base_hogares %>%
  filter(area_residencia != "Sin información") %>%
  count(area_residencia) %>%
  mutate(porcentaje = round(n / sum(n) * 100, 1))

write_csv(
  tabla_area %>%
    transmute(
      `Área de residencia` = area_residencia,
      Hogares = n,
      `Porcentaje de hogares` = porcentaje
    ),
  "outputs/explorar/eda_univariado_area_residencia.csv"
)

# Distribución de personas según sexo.
tabla_sexo <- base_personas %>%
  filter(sexo_recodificado != "Sin información") %>%
  count(sexo_recodificado) %>%
  mutate(porcentaje = round(n / sum(n) * 100, 1))

write_csv(
  tabla_sexo %>%
    transmute(
      Sexo = sexo_recodificado,
      Personas = n,
      `Porcentaje de personas` = porcentaje
    ),
  "outputs/explorar/eda_univariado_sexo.csv"
)

# Distribución de personas según grupo de edad.
tabla_grupo_edad <- base_personas %>%
  filter(grupo_edad != "Sin información") %>%
  count(grupo_edad) %>%
  mutate(porcentaje = round(n / sum(n) * 100, 1))

write_csv(
  tabla_grupo_edad %>%
    transmute(
      `Grupo de edad` = grupo_edad,
      Personas = n,
      `Porcentaje de personas` = porcentaje
    ),
  "outputs/explorar/eda_univariado_grupo_edad.csv"
)

# ------------------------------------------------------------------------------
# 4. Tablas bivariadas
# ------------------------------------------------------------------------------

# Distribución del acceso a olla común dentro de cada área de residencia.
# Unidad de análisis: hogar.
tabla_olla_area <- base_hogares_olla_valida %>%
  filter(area_residencia != "Sin información") %>%
  count(area_residencia, acceso_olla_comun) %>%
  group_by(area_residencia) %>%
  mutate(porcentaje = round(n / sum(n) * 100, 1)) %>%
  ungroup()

write_csv(
  tabla_olla_area %>%
    transmute(
      `Área de residencia` = area_residencia,
      `Acceso a olla común` = acceso_olla_comun,
      Hogares = n,
      `Porcentaje dentro del área` = porcentaje
    ),
  "outputs/explorar/eda_bivariado_olla_por_area.csv"
)

# Distribución del acceso del hogar según sexo de sus integrantes.
# Unidad de análisis: persona.
tabla_olla_sexo <- base_personas_olla_valida %>%
  filter(sexo_recodificado != "Sin información") %>%
  count(sexo_recodificado, acceso_olla_comun) %>%
  group_by(sexo_recodificado) %>%
  mutate(porcentaje = round(n / sum(n) * 100, 1)) %>%
  ungroup()

write_csv(
  tabla_olla_sexo %>%
    transmute(
      Sexo = sexo_recodificado,
      `Acceso del hogar a olla común` = acceso_olla_comun,
      Personas = n,
      `Porcentaje dentro del sexo` = porcentaje
    ),
  "outputs/explorar/eda_bivariado_olla_por_sexo.csv"
)

# Distribución del acceso del hogar según grupo de edad de sus integrantes.
# Unidad de análisis: persona.
tabla_olla_edad <- base_personas_olla_valida %>%
  filter(grupo_edad != "Sin información") %>%
  count(grupo_edad, acceso_olla_comun) %>%
  group_by(grupo_edad) %>%
  mutate(porcentaje = round(n / sum(n) * 100, 1)) %>%
  ungroup()

write_csv(
  tabla_olla_edad %>%
    transmute(
      `Grupo de edad` = grupo_edad,
      `Acceso del hogar a olla común` = acceso_olla_comun,
      Personas = n,
      `Porcentaje dentro del grupo` = porcentaje
    ),
  "outputs/explorar/eda_bivariado_olla_por_grupo_edad.csv"
)

# ------------------------------------------------------------------------------
# 5. Gráficos univariados
# ------------------------------------------------------------------------------

# Etiquetas breves para presentar el acceso sin repetir la pregunta completa.
tabla_acceso_olla_graf <- tabla_acceso_olla %>%
  mutate(
    acceso_grafico = recode(
      acceso_olla_comun,
      "No obtuvo alimentos de olla común" = "No accedió",
      "Sí obtuvo alimentos de olla común" = "Accedió"
    ),
    etiqueta_porcentaje = paste0(sprintf("%.1f", porcentaje), "%")
  )

grafico_acceso_olla <- ggplot(
  tabla_acceso_olla_graf,
  aes(x = reorder(acceso_grafico, porcentaje), y = porcentaje)
) +
  geom_col() +
  geom_text(
    aes(label = etiqueta_porcentaje),
    hjust = -0.1,
    size = 4
  ) +
  coord_flip() +
  labs(
    title = "Hogares según acceso a alimentos de olla común",
    x = NULL,
    y = "Porcentaje de hogares",
    caption = "Fuente: INEI, ENAHO 2024"
  ) +
  scale_y_continuous(
    expand = expansion(mult = c(0, 0.08))
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold")
  )

ggsave(
  "outputs/explorar/grafico_eda_acceso_olla.png",
  grafico_acceso_olla,
  width = 8,
  height = 5,
  bg = "white"
)

tabla_area_graf <- tabla_area %>%
  mutate(
    etiqueta_porcentaje = paste0(sprintf("%.1f", porcentaje), "%")
  )

grafico_area <- ggplot(
  tabla_area_graf,
  aes(x = area_residencia, y = porcentaje)
) +
  geom_col() +
  geom_text(
    aes(label = etiqueta_porcentaje),
    vjust = -0.3,
    size = 4
  ) +
  labs(
    title = "Hogares según área de residencia",
    x = "Área de residencia",
    y = "Porcentaje de hogares",
    caption = "Fuente: INEI, ENAHO 2024"
  ) +
  scale_y_continuous(
    expand = expansion(mult = c(0, 0.08))
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold")
  )

ggsave(
  "outputs/explorar/grafico_eda_area_residencia.png",
  grafico_area,
  width = 7,
  height = 5,
  bg = "white"
)

# ------------------------------------------------------------------------------
# 6. Gráficos bivariados
# ------------------------------------------------------------------------------

# Porcentaje de hogares que accedieron a alimentos de olla común en cada área.
datos_grafico_olla_area <- tabla_olla_area %>%
  filter(acceso_olla_comun == "Sí obtuvo alimentos de olla común") %>%
  mutate(
    etiqueta_porcentaje = paste0(sprintf("%.2f", porcentaje), "%")
  )

grafico_olla_area <- ggplot(
  datos_grafico_olla_area,
  aes(x = area_residencia, y = porcentaje)
) +
  geom_col() +
  geom_text(
    aes(label = etiqueta_porcentaje),
    vjust = -0.4,
    size = 4
  ) +
  labs(
    title = "Acceso a olla común según área de residencia",
    x = "Área de residencia",
    y = "Hogares con acceso (%)",
    caption = "Fuente: INEI, ENAHO 2024"
  ) +
  scale_y_continuous(
    expand = expansion(mult = c(0, 0.15))
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold")
  )

ggsave(
  "outputs/explorar/grafico_eda_olla_por_area.png",
  grafico_olla_area,
  width = 7,
  height = 5,
  bg = "white"
)

# Porcentaje de personas que viven en hogares con acceso, según grupo de edad.
datos_grafico_olla_edad <- tabla_olla_edad %>%
  filter(acceso_olla_comun == "Sí obtuvo alimentos de olla común") %>%
  mutate(
    grupo_edad = factor(
      grupo_edad,
      levels = c("Menor de 18", "18 a 29", "30 a 59", "60 a más")
    ),
    etiqueta_porcentaje = paste0(sprintf("%.1f", porcentaje), "%")
  )

grafico_olla_edad <- ggplot(
  datos_grafico_olla_edad,
  aes(x = grupo_edad, y = porcentaje)
) +
  geom_col() +
  geom_text(
    aes(label = etiqueta_porcentaje),
    vjust = -0.4,
    size = 4
  ) +
  labs(
    title = "Acceso del hogar a olla común según grupo de edad",
    x = "Grupo de edad",
    y = "Personas en hogares con acceso (%)",
    caption = "Fuente: INEI, ENAHO 2024"
  ) +
  scale_y_continuous(
    expand = expansion(mult = c(0, 0.15))
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold")
  )

ggsave(
  "outputs/explorar/grafico_eda_olla_por_grupo_edad.png",
  grafico_olla_edad,
  width = 8,
  height = 5,
  bg = "white"
)