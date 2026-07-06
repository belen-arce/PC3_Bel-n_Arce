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
# 2. Crear variables dummy y recodificaciones
# ------------------------------------------------------------------------------

base_clasificada <- base_acondicionada %>%
  mutate(
    # Dummies de condiciones materiales del hogar
    piso_tierra = case_when(
      as.numeric(material_piso) == 6 ~ 1,
      !is.na(material_piso) ~ 0,
      TRUE ~ NA_real_
    ),
    
    agua_no_red_publica = case_when(
      as.numeric(procedencia_agua) %in% c(1, 2) ~ 0,
      !is.na(procedencia_agua) ~ 1,
      TRUE ~ NA_real_
    ),
    
    saneamiento_no_red_publica = case_when(
      as.numeric(servicio_higienico) %in% c(1, 2) ~ 0,
      !is.na(servicio_higienico) ~ 1,
      TRUE ~ NA_real_
    ),
    
    sin_internet = case_when(
      as.numeric(internet) == 1 ~ 0,
      as.numeric(internet) == 2 ~ 1,
      TRUE ~ NA_real_
    ),
    
    # Variable personal: posible dependencia por edad
    persona_dependiente = case_when(
      edad < 18 | edad >= 60 ~ 1,
      edad >= 18 & edad < 60 ~ 0,
      TRUE ~ NA_real_
    )
  )

# ------------------------------------------------------------------------------
# 3. Crear índice de vulnerabilidad
# ------------------------------------------------------------------------------

base_clasificada <- base_clasificada %>%
  mutate(
    indice_vulnerabilidad_simple = rowSums(
      across(
        c(
          piso_tierra,
          agua_no_red_publica,
          saneamiento_no_red_publica,
          sin_internet,
          persona_dependiente
        )
      ),
      na.rm = TRUE
    ),
    
    nivel_vulnerabilidad = case_when(
      indice_vulnerabilidad_simple <= 1 ~ "Baja",
      indice_vulnerabilidad_simple == 2 ~ "Media",
      indice_vulnerabilidad_simple >= 3 ~ "Alta",
      TRUE ~ NA_character_
    )
  )

# ------------------------------------------------------------------------------
# 4. Crear tipología: olla común y vulnerabilidad
# ------------------------------------------------------------------------------

base_clasificada <- base_clasificada %>%
  mutate(
    registra_olla_comun = case_when(
      str_detect(acceso_olla_comun, "Sí") ~ "Registra olla común",
      TRUE ~ "No registra olla común"
    ),
    
    tipologia_olla_vulnerabilidad = case_when(
      registra_olla_comun == "Registra olla común" &
        nivel_vulnerabilidad == "Alta" ~ "Registra olla común y vulnerabilidad alta",
      
      registra_olla_comun == "Registra olla común" &
        nivel_vulnerabilidad %in% c("Baja", "Media") ~ "Registra olla común y vulnerabilidad baja/media",
      
      registra_olla_comun == "No registra olla común" &
        nivel_vulnerabilidad == "Alta" ~ "No registra olla común y vulnerabilidad alta",
      
      registra_olla_comun == "No registra olla común" &
        nivel_vulnerabilidad %in% c("Baja", "Media") ~ "No registra olla común y vulnerabilidad baja/media",
      
      TRUE ~ NA_character_
    )
  )

# ------------------------------------------------------------------------------
# 5. Reportes de clasificación
# ------------------------------------------------------------------------------

reporte_nivel_vulnerabilidad <- base_clasificada %>%
  count(nivel_vulnerabilidad) %>%
  mutate(porcentaje = round(n / sum(n) * 100, 2))

write_csv(
  reporte_nivel_vulnerabilidad,
  "outputs/tablas/reporte_clasificacion_nivel_vulnerabilidad.csv"
)

reporte_tipologia <- base_clasificada %>%
  count(tipologia_olla_vulnerabilidad) %>%
  mutate(porcentaje = round(n / sum(n) * 100, 2))

write_csv(
  reporte_tipologia,
  "outputs/tablas/reporte_clasificacion_tipologia_olla_vulnerabilidad.csv"
)

reporte_dummies <- base_clasificada %>%
  summarise(
    porcentaje_piso_tierra = round(mean(piso_tierra, na.rm = TRUE) * 100, 2),
    porcentaje_agua_no_red_publica = round(mean(agua_no_red_publica, na.rm = TRUE) * 100, 2),
    porcentaje_saneamiento_no_red_publica = round(mean(saneamiento_no_red_publica, na.rm = TRUE) * 100, 2),
    porcentaje_sin_internet = round(mean(sin_internet, na.rm = TRUE) * 100, 2),
    porcentaje_persona_dependiente = round(mean(persona_dependiente, na.rm = TRUE) * 100, 2)
  ) %>%
  pivot_longer(
    cols = everything(),
    names_to = "variable",
    values_to = "porcentaje"
  )

write_csv(
  reporte_dummies,
  "outputs/tablas/reporte_clasificacion_dummies.csv"
)

# ------------------------------------------------------------------------------
# 6. Gráfico de clasificación
# ------------------------------------------------------------------------------

grafico_tipologia <- ggplot(
  reporte_tipologia,
  aes(x = reorder(tipologia_olla_vulnerabilidad, n), y = n)
) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Tipología de olla común y vulnerabilidad",
    x = "Tipología",
    y = "Número de personas"
  ) +
  theme_minimal()

ggsave(
  filename = "outputs/graficos/grafico_clasificacion_tipologia_olla_vulnerabilidad.png",
  plot = grafico_tipologia,
  width = 9,
  height = 6,
  bg = "white"
)

# ------------------------------------------------------------------------------
# 7. Guardar base clasificada
# ------------------------------------------------------------------------------

write_parquet(
  base_clasificada,
  "datos/procesados/enaho_ollas_comunes_base_clasificada.parquet"
)
