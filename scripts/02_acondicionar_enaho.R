# ==============================================================================
# Proyecto: Ollas comunes y condiciones de vida con ENAHO 2024
# Script: 02_acondicionar_enaho.R
# Autora: Belén Arce
#
# Objetivo:
# Seleccionar, renombrar y recodificar las variables necesarias para las etapas
# de exploración y clasificación del proyecto.
#
# Unidad de análisis:
# La base mantiene una fila por persona. Las características del hogar se repiten
# entre sus integrantes porque provienen de los módulos 100 y 613.
#
# Tratamiento de valores perdidos:
# Los valores NA no se imputan. En las variables categóricas creadas se utiliza
# "Sin información" para conservar y distinguir los casos sin respuesta.
#
# Productos:
# - Base acondicionada en formato Parquet.
# - Reporte porcentual de valores perdidos.
# - Gráfico de valores perdidos por variable.
#
# Fecha de creación: 21-06-2026
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

# Las recodificaciones crean etiquetas legibles para las etapas posteriores.
# Las variables originales se conservan para mantener la trazabilidad.
# Los casos sin respuesta se identifican como "Sin información" y no se imputan.

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
  summarise(
    across(
      everything(),
      list(
        casos_perdidos = ~ sum(is.na(.)),
        porcentaje_perdidos = ~ round(mean(is.na(.)) * 100, 1)
      ),
      .names = "{.col}__{.fn}"
    )
  ) %>%
  pivot_longer(
    cols = everything(),
    names_to = c("Variable", ".value"),
    names_sep = "__"
  ) %>%
  rename(
    `Casos perdidos` = casos_perdidos,
    `Datos perdidos (%)` = porcentaje_perdidos
  ) %>%
  arrange(desc(`Datos perdidos (%)`))

write_csv(
  reporte_nas,
  "outputs/acondicionar/reporte_nas_ollas_comunes.csv"
)

# ------------------------------------------------------------------------------
# 7. Gráfico de valores perdidos
# ------------------------------------------------------------------------------

# Mostrar únicamente las diez variables con mayor porcentaje de datos perdidos.

datos_grafico_nas <- reporte_nas %>%
  filter(`Datos perdidos (%)` > 0) %>%
  slice_max(
    order_by = `Datos perdidos (%)`,
    n = 10,
    with_ties = FALSE
  ) %>%
  mutate(
    Variable = recode(
      Variable,
      residente_habitual = "Condición de residente habitual",
      miembro_hogar = "Condición de miembro del hogar",
      sexo = "Sexo",
      edad = "Edad",
      obtuvo_alimentos_olla_num = "Acceso a alimentos de olla común",
      existe_olla_zona_num = "Existencia de olla común en la zona",
      tipo_vivienda = "Tipo de vivienda",
      material_piso = "Material del piso",
      material_paredes = "Material de las paredes",
      habitaciones = "Número de habitaciones"
    )
  )

grafico_nas <- ggplot(
  datos_grafico_nas,
  aes(
    x = reorder(Variable, `Datos perdidos (%)`),
    y = `Datos perdidos (%)`
  )
) +
  geom_col() +
  geom_text(
    aes(label = sprintf("%.1f%%", `Datos perdidos (%)`)),
    hjust = -0.1,
    size = 3.5
  ) +
  coord_flip() +
  labs(
    title = "Variables con mayor proporción de datos perdidos",
    x = NULL,
    y = "Datos perdidos (%)",
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
  filename = "outputs/acondicionar/grafico_nas_ollas_comunes.png",
  plot = grafico_nas,
  width = 8,
  height = 6,
  bg = "white"
)

# ------------------------------------------------------------------------------
# 8. Guardar base acondicionada
# ------------------------------------------------------------------------------

write_parquet(
  base_acondicionada,
  "datos/procesados/enaho_ollas_comunes_base_acondicionada.parquet"
)
