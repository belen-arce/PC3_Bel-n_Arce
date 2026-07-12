# ==============================================================================
# Proyecto: Ollas comunes, vulnerabilidad alimentaria y condiciones de vida usando datos de la ENAHO
# Autora: Belén Arce
# Objetivo: Crear la estructura de carpetas, configurar renv y preparar Git/GitHub
# Fecha: 21-06-2026
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Creación de estructura de carpetas
# ------------------------------------------------------------------------------

# Crear la estructura de carpetas del proyecto
carpetas_proyecto <- c(
  "datos/crudos",
  "datos/procesados",
  "outputs/acondicionar",
  "outputs/explorar",
  "outputs/clasificar",
  "outputs/documentar",
  "docs",
  "scripts"
)

purrr::walk(
  carpetas_proyecto,
  ~ dir.create(.x, recursive = TRUE, showWarnings = FALSE)
)

# Archivos .gitkeep para que GitHub muestre carpetas vacías
file.create("outputs/acondicionar/.gitkeep")
file.create("outputs/explorar/.gitkeep")
file.create("outputs/clasificar/.gitkeep")
file.create("outputs/documentar/.gitkeep")

# ------------------------------------------------------------------------------
# 2. Actualización del .gitignore
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
  "# Conservar los reportes CSV del trabajo final",
  "!outputs/acondicionar/*.csv",
  "!outputs/explorar/*.csv",
  "!outputs/clasificar/*.csv",
  "!outputs/documentar/*.csv",
  "",
  "# Archivos temporales de R y RStudio",
  ".Rhistory",
  ".RData",
  ".RDataTmp",
  ".Ruserdata",
  ".Rproj.user/",
  "",
  "# renv",
  "renv/library/",
  "renv/staging/"
)

writeLines(gitignore_text, ".gitignore")

# ------------------------------------------------------------------------------
# 3. Instalación de paquetes necesarios para el proyecto
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
# 4. Activación renv para reproducibilidad
# ------------------------------------------------------------------------------


if (file.exists("renv.lock")) {
  message(
    "renv.lock encontrado. Para restaurar las dependencias, ejecute renv::restore()."
  )
} else {
  message(
    "No se encontró renv.lock. Inicialice renv una sola vez con renv::init()."
  )
}

# ------------------------------------------------------------------------------
# 5. Enlace con Git y GitHub
# ------------------------------------------------------------------------------

# Primero haremos un commit inicial.

# usethis::use_git()
# usethis::create_github_token()
# gitcreds::gitcreds_set()
# usethis::use_github(private = FALSE)
