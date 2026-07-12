# ==============================================================================
# Proyecto: Ollas comunes, vulnerabilidad alimentaria y condiciones de vida usando datos de la ENAHO
# Script: 04_clasificar_enaho.R
# Autora: Belén Arce
# Objetivo: Crear variables analíticas de clasificación 
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
# 2. Crear indicadores de vulnerabilidad material
# ------------------------------------------------------------------------------

base_clasificada <- base_acondicionada %>%
  mutate(
    # Piso de tierra: P103 = 6
    piso_tierra = case_when(
      as.numeric(material_piso) == 6 ~ 1,
      !is.na(material_piso) ~ 0,
      TRUE ~ NA_real_
    ),
    
    # Agua que no proviene de red pública dentro/fuera de la vivienda o edificio
    agua_no_red_publica = case_when(
      as.numeric(procedencia_agua) %in% c(1, 2) ~ 0,
      !is.na(procedencia_agua) ~ 1,
      TRUE ~ NA_real_
    ),
    
    # Servicio higiénico que no está conectado a red pública
    saneamiento_no_red_publica = case_when(
      as.numeric(servicio_higienico) %in% c(1, 2) ~ 0,
      !is.na(servicio_higienico) ~ 1,
      TRUE ~ NA_real_
    ),
    
    # Internet: P1144 usa 1 = tiene conexión, 0 = pase/no registra conexión
    sin_internet = case_when(
      as.numeric(internet) == 1 ~ 0,
      as.numeric(internet) == 0 ~ 1,
      TRUE ~ NA_real_
    )
  )

# ------------------------------------------------------------------------------
# 3. Crear índice simple de vulnerabilidad
# ------------------------------------------------------------------------------

indicadores_vulnerabilidad <- c(
  "piso_tierra",
  "agua_no_red_publica",
  "saneamiento_no_red_publica",
  "sin_internet"
)

base_clasificada <- base_clasificada %>%
  mutate(
    n_indicadores_validos = rowSums(
      !is.na(pick(all_of(indicadores_vulnerabilidad)))
    ),
    
    indice_vulnerabilidad_simple = if_else(
      n_indicadores_validos >= 3,
      rowSums(pick(all_of(indicadores_vulnerabilidad)), na.rm = TRUE),
      NA_real_
    ),
    
    nivel_vulnerabilidad = case_when(
      indice_vulnerabilidad_simple <= 1 ~ "Baja",
      indice_vulnerabilidad_simple == 2 ~ "Media",
      indice_vulnerabilidad_simple >= 3 ~ "Alta",
      TRUE ~ "Sin información"
    )
  )

# ------------------------------------------------------------------------------
# 4. Crear tipología entre acceso a olla común y vulnerabilidad
# ------------------------------------------------------------------------------

base_clasificada <- base_clasificada %>%
  mutate(
    acceso_olla_clasificado = case_when(
      acceso_olla_comun == "Sí obtuvo alimentos de olla común" ~ "Accedió a olla común",
      acceso_olla_comun == "No obtuvo alimentos de olla común" ~ "No accedió a olla común",
      TRUE ~ "Sin información"
    ),
    
    tipologia_olla_vulnerabilidad = case_when(
      acceso_olla_clasificado == "Accedió a olla común" &
        nivel_vulnerabilidad == "Alta" ~ "Accedió a olla común y vulnerabilidad alta",
      
      acceso_olla_clasificado == "Accedió a olla común" &
        nivel_vulnerabilidad %in% c("Baja", "Media") ~ "Accedió a olla común y vulnerabilidad baja/media",
      
      acceso_olla_clasificado == "No accedió a olla común" &
        nivel_vulnerabilidad == "Alta" ~ "No accedió a olla común y vulnerabilidad alta",
      
      acceso_olla_clasificado == "No accedió a olla común" &
        nivel_vulnerabilidad %in% c("Baja", "Media") ~ "No accedió a olla común y vulnerabilidad baja/media",
      
      TRUE ~ "Sin información"
    )
  )

# ------------------------------------------------------------------------------
# 5. Crear base a nivel hogar para reportes
# ------------------------------------------------------------------------------

base_hogares_clasificada <- base_clasificada %>%
  distinct(conglome, vivienda, hogar, .keep_all = TRUE)

# ------------------------------------------------------------------------------
# 6. Reportes de clasificación
# ------------------------------------------------------------------------------

reporte_nivel_vulnerabilidad <- base_hogares_clasificada %>%
  filter(nivel_vulnerabilidad != "Sin información") %>%
  count(nivel_vulnerabilidad) %>%
  mutate(porcentaje = round(n / sum(n) * 100, 2))

write_csv(
  reporte_nivel_vulnerabilidad,
  "outputs/clasificar/reporte_clasificacion_nivel_vulnerabilidad.csv"
)

reporte_tipologia <- base_hogares_clasificada %>%
  filter(
    tipologia_olla_vulnerabilidad != "Sin información",
    acceso_olla_clasificado != "Sin información",
    nivel_vulnerabilidad != "Sin información"
  ) %>%
  count(tipologia_olla_vulnerabilidad) %>%
  mutate(porcentaje = round(n / sum(n) * 100, 2))

write_csv(
  reporte_tipologia,
  "outputs/clasificar/reporte_clasificacion_tipologia_olla_vulnerabilidad.csv"
)

reporte_dummies <- base_hogares_clasificada %>%
  summarise(
    porcentaje_piso_tierra = round(mean(piso_tierra, na.rm = TRUE) * 100, 2),
    porcentaje_agua_no_red_publica = round(mean(agua_no_red_publica, na.rm = TRUE) * 100, 2),
    porcentaje_saneamiento_no_red_publica = round(mean(saneamiento_no_red_publica, na.rm = TRUE) * 100, 2),
    porcentaje_sin_internet = round(mean(sin_internet, na.rm = TRUE) * 100, 2)
  ) %>%
  pivot_longer(
    cols = everything(),
    names_to = "variable",
    values_to = "porcentaje"
  )

write_csv(
  reporte_dummies,
  "outputs/clasificar/reporte_clasificacion_dummies.csv"
)

# ------------------------------------------------------------------------------
# 7. Reporte de variables creadas
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
    
    tibble(
      variable = nombre_variable,
      casos_validos = sum(!is.na(x)),
      porcentaje_perdidos = round(mean(is.na(x)) * 100, 1)
    )
  }
)

reporte_detallado_variables <- descripcion_variables_creadas %>%
  left_join(resumen_variables_creadas, by = "variable") %>%
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
# 8. Gráfico de clasificación
# ------------------------------------------------------------------------------

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
    subtitle = NULL,
    caption = "Fuente: INEI, ENAHO 2024",
    x = NULL,
    y = "Porcentaje de hogares"
  ) +
  scale_y_continuous(
    limits = c(0, max(reporte_tipologia$porcentaje) + 8),
    expand = expansion(mult = c(0, 0.02))
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold"),
    axis.text.y = element_text(size = 10)
  )

ggsave(
  "outputs/clasificar/grafico_clasificacion_tipologia_olla_vulnerabilidad.png",
  grafico_tipologia,
  width = 10,
  height = 6,
  bg = "white"
)

# ------------------------------------------------------------------------------
# 9. Guardar base clasificada
# ------------------------------------------------------------------------------

write_parquet(
  base_clasificada,
  "datos/procesados/enaho_ollas_comunes_base_clasificada.parquet"
)
