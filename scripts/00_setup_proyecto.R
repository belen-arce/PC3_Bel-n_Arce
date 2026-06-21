# ==============================================================================
# Proyecto: Ollas comunes, vulnerabilidad alimentaria y condiciones de vida usando datos de la ENAHO
# Autora: Belén Arce
# Objetivo: Crear la estructura de carpetas, configurar renv y preparar Git/GitHub
# Fecha: 21-06-2026
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Crear estructura de carpetas
# ------------------------------------------------------------------------------

dir.create("datos", showWarnings = FALSE)
dir.create("datos/crudos", showWarnings = FALSE)
dir.create("datos/procesados", showWarnings = FALSE)

dir.create("outputs", showWarnings = FALSE)
dir.create("outputs/graficos", showWarnings = FALSE)
dir.create("outputs/tablas", showWarnings = FALSE)

dir.create("docs", showWarnings = FALSE)
dir.create("scripts", showWarnings = FALSE)

# Archivos .gitkeep para que GitHub muestre carpetas vacías
file.create("datos/crudos/.gitkeep")
file.create("datos/procesados/.gitkeep")
file.create("outputs/graficos/.gitkeep")
file.create("outputs/tablas/.gitkeep")
file.create("docs/.gitkeep")

# ------------------------------------------------------------------------------
# 2. Actualizar .gitignore
# ------------------------------------------------------------------------------

gitignore_text <- c(
  "# Datos crudos y procesados no se suben a GitHub",
  "datos/crudos/*",
  "datos/procesados/*",
  "!datos/crudos/.gitkeep",
  "!datos/procesados/.gitkeep",
  "",
  "# Archivos pesados de datos",
  "*.sav",
  "*.dta",
  "*.csv",
  "*.xlsx",
  "*.parquet",
  "*.rds",
  "",
  "# Archivos temporales de R",
  ".Rhistory",
  ".RData",
  ".Ruserdata",
  "",
  "# renv",
  "renv/library/",
  "renv/staging/"
)

writeLines(gitignore_text, ".gitignore")

# ------------------------------------------------------------------------------
# 3. Instalar paquetes necesarios para el proyecto
# ------------------------------------------------------------------------------

paquetes <- c(
  "tidyverse",
  "rio",
  "haven",
  "arrow",
  "janitor",
  "naniar",
  "renv",
  "usethis",
  "gitcreds"
)

paquetes_faltantes <- paquetes[!paquetes %in% rownames(installed.packages())]

if (length(paquetes_faltantes) > 0) {
  install.packages(paquetes_faltantes)
}

# ------------------------------------------------------------------------------
# 4. Activar renv para reproducibilidad
# ------------------------------------------------------------------------------

renv::consent(provided = TRUE)
renv::init(bare = TRUE)
renv::snapshot(prompt = FALSE)

# ------------------------------------------------------------------------------
# 5. Enlace con Git y GitHub
# ------------------------------------------------------------------------------

# Primero haremos un commit inicial.

# usethis::use_git()
# usethis::create_github_token()
# gitcreds::gitcreds_set()
# usethis::use_github(private = FALSE)
