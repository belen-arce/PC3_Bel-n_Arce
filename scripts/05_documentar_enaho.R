# ==============================================================================
# Proyecto: Ollas comunes, vulnerabilidad alimentaria y condiciones de vida
# Script: 05_documentar_enaho.R
# Autora: Belén Arce
# Objetivo: Generar el codebook de la base final procesada y registrar
#           la información del entorno de trabajo
# ==============================================================================

library(tidyverse)
library(arrow)

# ------------------------------------------------------------------------------
# 1. Cargar la base final clasificada
# ------------------------------------------------------------------------------

base_final <- read_parquet(
  "datos/procesados/enaho_ollas_comunes_base_clasificada.parquet"
)

# ------------------------------------------------------------------------------
# 2. Creación del diagnóstico automático de cada variable
# ------------------------------------------------------------------------------

codebook_automatico <- map_dfr(names(base_final), function(nombre_variable) {
  
  x <- base_final[[nombre_variable]]
  
  valores_ejemplo <- unique(na.omit(as.character(x)))
  valores_ejemplo <- head(valores_ejemplo, 5)
  
  tibble(
    variable = nombre_variable,
    tipo_en_r = paste(class(x), collapse = " / "),
    total_casos = length(x),
    casos_validos = sum(!is.na(x)),
    casos_perdidos = sum(is.na(x)),
    porcentaje_perdidos = round(mean(is.na(x)) * 100, 2),
    valores_unicos = n_distinct(x, na.rm = TRUE),
    ejemplos = paste(valores_ejemplo, collapse = " | ")
  )
})

# ------------------------------------------------------------------------------
# 3. Descripción del origen y significado de las variables
# ------------------------------------------------------------------------------

metadatos_variables <- tribble(
  ~variable, ~origen, ~unidad_analisis, ~descripcion, ~codificacion_derivacion,
  
  "conglome", "Llave ENAHO", "Hogar", "Código del conglomerado muestral.", "Codificación original de ENAHO 2024.",
  "vivienda", "Llave ENAHO", "Vivienda", "Código de identificación de la vivienda.", "Codificación original de ENAHO 2024.",
  "hogar", "Llave ENAHO", "Hogar", "Código del hogar dentro de la vivienda.", "Codificación original de ENAHO 2024.",
  "codperso", "Módulo 200", "Persona", "Código de la persona dentro del hogar.", "Codificación original de ENAHO 2024.",
  
  "ano", "Módulo 100", "Hogar", "Año de ejecución de la encuesta.", "Valor correspondiente a 2024.",
  "mes", "Módulo 100", "Hogar", "Mes de ejecución de la encuesta.", "Codificación original de ENAHO 2024.",
  "ubigeo", "Módulo 100", "Hogar", "Código de ubicación geográfica del hogar.", "Codificación UBIGEO del INEI.",
  "dominio", "Módulo 100", "Hogar", "Dominio geográfico de la encuesta.", "Codificación original de ENAHO 2024.",
  "estrato", "Módulo 100", "Hogar", "Estrato geográfico y poblacional del hogar.", "Valores del 1 al 8 según el diseño muestral.",
  
  "tipo_vivienda", "Módulo 100", "Hogar", "Tipo de vivienda ocupada por el hogar.", "Variable original P101.",
  "material_paredes", "Módulo 100", "Hogar", "Material predominante de las paredes exteriores.", "Variable original P102.",
  "material_piso", "Módulo 100", "Hogar", "Material predominante del piso de la vivienda.", "Variable original P103.",
  "habitaciones", "Módulo 100", "Hogar", "Número de habitaciones de la vivienda.", "Variable original P104.",
  "procedencia_agua", "Módulo 100", "Hogar", "Fuente principal del agua utilizada por el hogar.", "Variable original P110.",
  "servicio_higienico", "Módulo 100", "Hogar", "Tipo de conexión del servicio higiénico.", "Variable original P111A.",
  "electricidad", "Módulo 100", "Hogar", "Disponibilidad de electricidad como alumbrado.", "Variable original P1121.",
  "internet", "Módulo 100", "Hogar", "Disponibilidad de conexión fija o móvil a internet.", "Variable original P1144.",
  
  "parentesco", "Módulo 200", "Persona", "Relación de parentesco con la jefatura del hogar.", "Variable original P203.",
  "miembro_hogar", "Módulo 200", "Persona", "Indica si la persona es miembro del hogar.", "Variable original P204.",
  "residente_habitual", "Módulo 200", "Persona", "Indica si la persona es residente habitual.", "Variable original P205.",
  "sexo", "Módulo 200", "Persona", "Sexo registrado para la persona encuestada.", "Variable original P207.",
  "edad", "Módulo 200", "Persona", "Edad de la persona en años cumplidos.", "Variable original P208A.",
  
  "registros_modulo_613", "Módulo 613", "Hogar", "Cantidad de registros encontrados para el hogar en el módulo de olla común.", "Conteo de filas por conglomerado, vivienda y hogar.",
  "existe_olla_zona_num", "Módulo 613", "Hogar", "Indicador numérico de existencia de una olla común en la zona.", "1 = sí; 0 = no; NA = sin información. Derivada de P613A.",
  "obtuvo_alimentos_olla_num", "Módulo 613", "Hogar", "Indicador numérico de acceso del hogar a alimentos de olla común.", "1 = sí; 0 = no; NA = sin información. Derivada de P613B.",
  "existencia_olla_zona", "Variable derivada", "Hogar", "Versión categórica de la existencia de una olla común en la zona.", "Sí existió, no existió o sin información.",
  "acceso_olla_comun", "Variable derivada", "Hogar", "Indica si el hogar obtuvo, compró o recibió alimentos de una olla común.", "Sí obtuvo, no obtuvo o sin información.",
  
  "sexo_recodificado", "Variable derivada", "Persona", "Versión categórica y legible de la variable sexo.", "1 = Hombre; 2 = Mujer; otros = Sin información.",
  "grupo_edad", "Variable derivada", "Persona", "Clasificación de las personas en grupos de edad.", "Menor de 18; 18 a 29; 30 a 59; 60 a más.",
  "area_residencia", "Variable derivada", "Hogar", "Clasificación operativa del área de residencia.", "Estratos 1 a 5 = urbana; estratos 6 a 8 = rural.",
  
  "piso_tierra", "Variable derivada", "Hogar", "Indicador de precariedad asociado a piso de tierra.", "1 si P103 = 6; 0 para otros materiales válidos.",
  "agua_no_red_publica", "Variable derivada", "Hogar", "Indicador de acceso a agua fuera de una red pública domiciliaria.", "0 si P110 es 1 o 2; 1 para otras fuentes válidas.",
  "saneamiento_no_red_publica", "Variable derivada", "Hogar", "Indicador de servicio higiénico no conectado a red pública.", "0 si P111A es 1 o 2; 1 para otras alternativas válidas.",
  "sin_internet", "Variable derivada", "Hogar", "Indicador de ausencia de conexión a internet.", "0 si P1144 = 1; 1 si P1144 = 0.",
  
  "n_indicadores_validos", "Variable derivada", "Hogar", "Número de indicadores disponibles para calcular el índice.", "Conteo de indicadores no perdidos entre cuatro condiciones materiales.",
  "indice_vulnerabilidad_simple", "Variable derivada", "Hogar", "Suma simple de privaciones materiales del hogar.", "Suma de piso de tierra, agua no pública, saneamiento no público y ausencia de internet. Se calcula con al menos tres indicadores válidos.",
  "nivel_vulnerabilidad", "Variable derivada", "Hogar", "Clasificación del índice simple de vulnerabilidad.", "Baja = 0 o 1; media = 2; alta = 3 o 4.",
  "acceso_olla_clasificado", "Variable derivada", "Hogar", "Recodificación resumida del acceso a olla común.", "Accedió, no accedió o sin información.",
  "tipologia_olla_vulnerabilidad", "Variable derivada", "Hogar", "Tipología que combina acceso a olla común y nivel de vulnerabilidad.", "Cruce entre acceso/no acceso y vulnerabilidad alta o baja/media."
)

# ------------------------------------------------------------------------------
# 4. Integración del diagnóstico y descripciones
# ------------------------------------------------------------------------------

codebook_final <- codebook_automatico %>%
  left_join(metadatos_variables, by = "variable") %>%
  mutate(
    origen = replace_na(origen, "Variable conservada de la base procesada"),
    unidad_analisis = replace_na(unidad_analisis, "Consultar según variable"),
    descripcion = replace_na(
      descripcion,
      "Variable conservada de la ENAHO 2024. Consultar el diccionario original."
    ),
    codificacion_derivacion = replace_na(
      codificacion_derivacion,
      "Codificación original de la ENAHO 2024."
    )
  ) %>%
  select(
    variable,
    origen,
    unidad_analisis,
    descripcion,
    codificacion_derivacion,
    tipo_en_r,
    total_casos,
    casos_validos,
    casos_perdidos,
    porcentaje_perdidos,
    valores_unicos,
    ejemplos
  )

# ------------------------------------------------------------------------------
# 5. Exportación el codebook
# ------------------------------------------------------------------------------

write_csv(
  codebook_final,
  "outputs/documentar/codebook_base_clasificada.csv"
)

# ------------------------------------------------------------------------------
# 6. Registro de información del entorno de R
# ------------------------------------------------------------------------------

capture.output(
  sessionInfo(),
  file = "outputs/documentar/session_info.txt"
)

message("Codebook y sessionInfo guardados correctamente en outputs/documentar")