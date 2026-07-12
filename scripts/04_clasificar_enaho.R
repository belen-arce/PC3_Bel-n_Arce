# ==============================================================================
# Proyecto: Ollas comunes y condiciones de vida con ENAHO 2024
# Script: 04_clasificar_enaho.R
# Autora: Belén Arce
#
# Objetivo:
# Crear indicadores de privación material, construir un índice descriptivo
# de vulnerabilidad y clasificar los hogares según su acceso a alimentos
# de olla común.
#
# Unidad de análisis:
# La base original conserva una fila por persona, pero los indicadores,
# el índice, las tipologías y los reportes se interpretan a nivel de hogar.
#
# Decisión metodológica:
# El índice suma cuatro privaciones materiales: piso de tierra, agua fuera
# de red pública, saneamiento fuera de red pública y ausencia de internet.
# Se calcula únicamente cuando existen al menos tres indicadores válidos.
#
# Alcance:
# El índice es una clasificación descriptiva creada para este ejercicio.
# No constituye una medición oficial de pobreza ni vulnerabilidad.
#
# Productos:
# - Base clasificada en formato Parquet.
# - Reportes de indicadores, niveles y tipologías en formato CSV.
# - Gráfico de acceso a olla común y nivel de vulnerabilidad.
#
# Fecha de creación: 05-07-2026
# ==============================================================================

library(tidyverse)
library(arrow)

# ------------------------------------------------------------------------------
# 1. Carga de la base acondicionada
# ------------------------------------------------------------------------------

base_acondicionada <- read_parquet(
  "datos/procesados/enaho_ollas_comunes_base_acondicionada.parquet"
)

# ------------------------------------------------------------------------------
# 2. Creación de indicadores de vulnerabilidad material
# ------------------------------------------------------------------------------

# Cada indicador representa una privación material del hogar:
# 1 = presenta la privación; 0 = no la presenta; NA = sin información.
# Las variables originales se conservan para mantener la trazabilidad.

base_clasificada <- base_acondicionada %>%
  mutate(
    # Piso de tierra: P103 = 6.
    piso_tierra = case_when(
      as.numeric(material_piso) == 6 ~ 1,
      !is.na(material_piso) ~ 0,
      TRUE ~ NA_real_
    ),
    
    # Agua que no procede de una red pública dentro o fuera de la vivienda.
    agua_no_red_publica = case_when(
      as.numeric(procedencia_agua) %in% c(1, 2) ~ 0,
      !is.na(procedencia_agua) ~ 1,
      TRUE ~ NA_real_
    ),
    
    # Servicio higiénico no conectado a una red pública de desagüe.
    saneamiento_no_red_publica = case_when(
      as.numeric(servicio_higienico) %in% c(1, 2) ~ 0,
      !is.na(servicio_higienico) ~ 1,
      TRUE ~ NA_real_
    ),
    
    # P1144: 1 = tiene conexión; 0 = no registra conexión.
    sin_internet = case_when(
      as.numeric(internet) == 1 ~ 0,
      as.numeric(internet) == 0 ~ 1,
      TRUE ~ NA_real_
    )
  )

# ------------------------------------------------------------------------------
# 3. Creación del índice simple de vulnerabilidad
# ------------------------------------------------------------------------------

indicadores_vulnerabilidad <- c(
  "piso_tierra",
  "agua_no_red_publica",
  "saneamiento_no_red_publica",
  "sin_internet"
)

base_clasificada <- base_clasificada %>%
  mutate(
    # Cantidad de indicadores con información disponible.
    n_indicadores_validos = rowSums(
      !is.na(pick(all_of(indicadores_vulnerabilidad)))
    ),
    
    # Suma de privaciones. Solo se calcula con al menos tres datos válidos.
    indice_vulnerabilidad_simple = if_else(
      n_indicadores_validos >= 3,
      rowSums(
        pick(all_of(indicadores_vulnerabilidad)),
        na.rm = TRUE
      ),
      NA_real_
    ),
    
    # Clasificación descriptiva del índice.
    nivel_vulnerabilidad = case_when(
      indice_vulnerabilidad_simple <= 1 ~ "Baja",
      indice_vulnerabilidad_simple == 2 ~ "Media",
      indice_vulnerabilidad_simple >= 3 ~ "Alta",
      TRUE ~ "Sin información"
    )
  )

# ------------------------------------------------------------------------------
# 4. Creación la tipología de acceso y vulnerabilidad
# ------------------------------------------------------------------------------

base_clasificada <- base_clasificada %>%
  mutate(
    acceso_olla_clasificado = case_when(
      acceso_olla_comun == "Sí obtuvo alimentos de olla común" ~
        "Accedió a olla común",
      
      acceso_olla_comun == "No obtuvo alimentos de olla común" ~
        "No accedió a olla común",
      
      TRUE ~ "Sin información"
    ),
    
    tipologia_olla_vulnerabilidad = case_when(
      acceso_olla_clasificado == "Accedió a olla común" &
        nivel_vulnerabilidad == "Alta" ~
        "Accedió a olla común y vulnerabilidad alta",
      
      acceso_olla_clasificado == "Accedió a olla común" &
        nivel_vulnerabilidad %in% c("Baja", "Media") ~
        "Accedió a olla común y vulnerabilidad baja/media",
      
      acceso_olla_clasificado == "No accedió a olla común" &
        nivel_vulnerabilidad == "Alta" ~
        "No accedió a olla común y vulnerabilidad alta",
      
      acceso_olla_clasificado == "No accedió a olla común" &
        nivel_vulnerabilidad %in% c("Baja", "Media") ~
        "No accedió a olla común y vulnerabilidad baja/media",
      
      TRUE ~ "Sin información"
    )
  )

# ------------------------------------------------------------------------------
# 5. Creación de una base a nivel de hogar para los reportes
# ------------------------------------------------------------------------------

# La base clasificada mantiene una fila por persona. Para calcular reportes
# del hogar se conserva una sola fila por combinación de llaves.

base_hogares_clasificada <- base_clasificada %>%
  distinct(conglome, vivienda, hogar, .keep_all = TRUE)

# Comprobar que cada hogar aparezca una sola vez.
stopifnot(
  nrow(base_hogares_clasificada) ==
    n_distinct(
      base_hogares_clasificada$conglome,
      base_hogares_clasificada$vivienda,
      base_hogares_clasificada$hogar
    )
)

# ------------------------------------------------------------------------------
# 6. Creación de reportes de clasificación
# ------------------------------------------------------------------------------

# Distribución de hogares según nivel de vulnerabilidad.
reporte_nivel_vulnerabilidad <- base_hogares_clasificada %>%
  filter(nivel_vulnerabilidad != "Sin información") %>%
  mutate(
    nivel_vulnerabilidad = factor(
      nivel_vulnerabilidad,
      levels = c("Baja", "Media", "Alta")
    )
  ) %>%
  count(nivel_vulnerabilidad) %>%
  mutate(
    porcentaje = round(n / sum(n) * 100, 1)
  )

write_csv(
  reporte_nivel_vulnerabilidad %>%
    transmute(
      `Nivel de vulnerabilidad` = nivel_vulnerabilidad,
      Hogares = n,
      `Porcentaje de hogares` = porcentaje
    ),
  "outputs/clasificar/reporte_clasificacion_nivel_vulnerabilidad.csv"
)

# Distribución de hogares según la tipología de acceso y vulnerabilidad.
reporte_tipologia <- base_hogares_clasificada %>%
  filter(
    tipologia_olla_vulnerabilidad != "Sin información",
    acceso_olla_clasificado != "Sin información",
    nivel_vulnerabilidad != "Sin información"
  ) %>%
  count(tipologia_olla_vulnerabilidad) %>%
  mutate(
    porcentaje = round(n / sum(n) * 100, 2)
  )

write_csv(
  reporte_tipologia %>%
    transmute(
      Tipología = tipologia_olla_vulnerabilidad,
      Hogares = n,
      `Porcentaje de hogares` = porcentaje
    ),
  "outputs/clasificar/reporte_clasificacion_tipologia_olla_vulnerabilidad.csv"
)

# Porcentaje de hogares que presenta cada privación material.
reporte_dummies <- base_hogares_clasificada %>%
  summarise(
    `Piso de tierra` =
      round(mean(piso_tierra, na.rm = TRUE) * 100, 1),
    
    `Agua fuera de red pública` =
      round(mean(agua_no_red_publica, na.rm = TRUE) * 100, 1),
    
    `Saneamiento fuera de red pública` =
      round(mean(saneamiento_no_red_publica, na.rm = TRUE) * 100, 1),
    
    `Sin conexión a internet` =
      round(mean(sin_internet, na.rm = TRUE) * 100, 1)
  ) %>%
  pivot_longer(
    cols = everything(),
    names_to = "Indicador",
    values_to = "Hogares con privación (%)"
  )

write_csv(
  reporte_dummies,
  "outputs/clasificar/reporte_clasificacion_dummies.csv"
)

# ------------------------------------------------------------------------------
# 7. Creación del reporte breve de variables derivadas
# ------------------------------------------------------------------------------

descripcion_variables_creadas <- tribble(
  ~variable, ~unidad_analisis, ~que_mide, ~codificacion,
  
  "piso_tierra",
  "Hogar",
  "Presencia de piso de tierra.",
  "1 = Sí; 0 = No",
  
  "agua_no_red_publica",
  "Hogar",
  "Agua fuera de una red pública.",
  "1 = Sí; 0 = No",
  
  "saneamiento_no_red_publica",
  "Hogar",
  "Saneamiento fuera de una red pública.",
  "1 = Sí; 0 = No",
  
  "sin_internet",
  "Hogar",
  "Ausencia de conexión a internet.",
  "1 = Sí; 0 = No",
  
  "n_indicadores_validos",
  "Hogar",
  "Cantidad de indicadores disponibles.",
  "Valores de 0 a 4",
  
  "indice_vulnerabilidad_simple",
  "Hogar",
  "Número de privaciones materiales.",
  "Valores de 0 a 4",
  
  "nivel_vulnerabilidad",
  "Hogar",
  "Nivel de vulnerabilidad material.",
  "Baja; Media; Alta",
  
  "acceso_olla_clasificado",
  "Hogar",
  "Acceso a alimentos de olla común.",
  "Accedió; No accedió",
  
  "tipologia_olla_vulnerabilidad",
  "Hogar",
  "Combinación entre acceso y vulnerabilidad.",
  "Cuatro categorías"
)

resumen_variables_creadas <- map_dfr(
  descripcion_variables_creadas$variable,
  function(nombre_variable) {
    
    x <- base_hogares_clasificada[[nombre_variable]]
    
    # En las variables categóricas, "Sin información" se considera
    # equivalente a un dato perdido para este reporte.
    casos_sin_informacion <- is.na(x) |
      as.character(x) == "Sin información"
    
    tibble(
      variable = nombre_variable,
      casos_validos = sum(!casos_sin_informacion),
      porcentaje_perdidos = round(
        mean(casos_sin_informacion) * 100,
        1
      )
    )
  }
)

reporte_detallado_variables <- descripcion_variables_creadas %>%
  left_join(
    resumen_variables_creadas,
    by = "variable"
  ) %>%
  rename(
    Variable = variable,
    `Unidad de análisis` = unidad_analisis,
    `Qué mide` = que_mide,
    Codificación = codificacion,
    `Casos válidos` = casos_validos,
    `Datos perdidos (%)` = porcentaje_perdidos
  )

write_csv(
  reporte_detallado_variables,
  "outputs/clasificar/reporte_detallado_variables_creadas.csv"
)

# ------------------------------------------------------------------------------
# 8. Creación del gráfico de clasificación
# ------------------------------------------------------------------------------

# Se utilizan etiquetas breves para facilitar la lectura del gráfico.
reporte_tipologia_graf <- reporte_tipologia %>%
  mutate(
    tipologia_grafico = case_when(
      tipologia_olla_vulnerabilidad ==
        "No accedió a olla común y vulnerabilidad baja/media" ~
        "No accedió\nVulnerabilidad baja/media",
      
      tipologia_olla_vulnerabilidad ==
        "No accedió a olla común y vulnerabilidad alta" ~
        "No accedió\nVulnerabilidad alta",
      
      tipologia_olla_vulnerabilidad ==
        "Accedió a olla común y vulnerabilidad baja/media" ~
        "Accedió\nVulnerabilidad baja/media",
      
      tipologia_olla_vulnerabilidad ==
        "Accedió a olla común y vulnerabilidad alta" ~
        "Accedió\nVulnerabilidad alta",
      
      TRUE ~ tipologia_olla_vulnerabilidad
    ),
    
    etiqueta_porcentaje = case_when(
      porcentaje < 0.1 ~ "<0.1%",
      TRUE ~ paste0(round(porcentaje, 1), "%")
    )
  )

grafico_tipologia <- ggplot(
  reporte_tipologia_graf,
  aes(
    x = reorder(tipologia_grafico, porcentaje),
    y = porcentaje
  )
) +
  geom_col() +
  geom_text(
    aes(label = etiqueta_porcentaje),
    hjust = -0.1,
    size = 3.6
  ) +
  coord_flip() +
  labs(
    title = "Acceso a olla común y nivel de vulnerabilidad",
    x = NULL,
    y = "Porcentaje de hogares",
    caption = "Fuente: INEI, ENAHO 2024"
  ) +
  scale_y_continuous(
    limits = c(
      0,
      max(reporte_tipologia$porcentaje) + 8
    ),
    expand = expansion(mult = c(0, 0.02))
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold"),
    axis.text.y = element_text(size = 10)
  )

ggsave(
  filename =
    "outputs/clasificar/grafico_clasificacion_tipologia_olla_vulnerabilidad.png",
  plot = grafico_tipologia,
  width = 10,
  height = 6,
  bg = "white"
)

# ------------------------------------------------------------------------------
# 9. Guardar la base clasificada
# ------------------------------------------------------------------------------

ruta_base_clasificada <-
  "datos/procesados/enaho_ollas_comunes_base_clasificada.parquet"

write_parquet(
  base_clasificada,
  ruta_base_clasificada
)

message(
  "Base clasificada guardada en: ",
  ruta_base_clasificada
)