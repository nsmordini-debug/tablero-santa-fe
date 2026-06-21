# librarys ---------------------------------------------------------------

library(readxl)
library(shiny)
library(bslib)
library(dplyr)
library(leaflet)
library(ggplot2)
library(shinyWidgets)
library(tidyr)
library(highcharter)
library(reactable)
library(shinyjs)
library(shinyWidgets)
library(stringr)
library(sf)

# helpers ----------------------------------------------------------------------

source("helpers/helpers_persona.R")
source("helpers/helpers_lugar.R")
source("helpers/helpers_tiempo.R")
source("helpers/helpers_indicadores.R")

# módulos ----------------------------------------------------------------------

source("modulos/modulo_persona.R")
source("modulos/modulo_lugar.R")
source("modulos/modulo_tiempo.R")
source("modulos/modulo_indicadores.R")

# base ------------------------------------------------------------------------

datos_22_55 <- read_excel("archivos/eventos_2022-2026.xlsx", sheet = "2025_2022") 
datos_26 <- read_excel("archivos/eventos_2022-2026.xlsx", sheet = "2026")   
  
base_eventos <- datos_22_55 |>
  rbind(datos_26)|>
  mutate(
    GRUPO = case_when(
      EDAD_DIAGNOSTICO < 1 ~ "Menores de 1 año",
      EDAD_DIAGNOSTICO >= 1  & EDAD_DIAGNOSTICO <= 4  ~ "1-4 años",
      EDAD_DIAGNOSTICO >= 5  & EDAD_DIAGNOSTICO <= 9  ~ "5-9 años",
      EDAD_DIAGNOSTICO >= 10 & EDAD_DIAGNOSTICO <= 14 ~ "10-14 años",
      EDAD_DIAGNOSTICO >= 15 & EDAD_DIAGNOSTICO <= 19 ~ "15-19 años",
      EDAD_DIAGNOSTICO >= 20 & EDAD_DIAGNOSTICO <= 24 ~ "20-24 años",
      EDAD_DIAGNOSTICO >= 25 & EDAD_DIAGNOSTICO <= 29 ~ "25-29 años",
      EDAD_DIAGNOSTICO >= 30 & EDAD_DIAGNOSTICO <= 34 ~ "30-34 años",
      EDAD_DIAGNOSTICO >= 35 & EDAD_DIAGNOSTICO <= 39 ~ "35-39 años",
      EDAD_DIAGNOSTICO >= 40 & EDAD_DIAGNOSTICO <= 44 ~ "40-44 años",
      EDAD_DIAGNOSTICO >= 45 & EDAD_DIAGNOSTICO <= 49 ~ "45-49 años",
      EDAD_DIAGNOSTICO >= 50 & EDAD_DIAGNOSTICO <= 54 ~ "50-54 años",
      EDAD_DIAGNOSTICO >= 55 & EDAD_DIAGNOSTICO <= 59 ~ "55-59 años",
      EDAD_DIAGNOSTICO >= 60 & EDAD_DIAGNOSTICO <= 64 ~ "60-64 años",
      EDAD_DIAGNOSTICO >= 65 & EDAD_DIAGNOSTICO <= 69 ~ "65-69 años",
      EDAD_DIAGNOSTICO >= 70 & EDAD_DIAGNOSTICO <= 74 ~ "70-74 años",
      EDAD_DIAGNOSTICO >= 75 & EDAD_DIAGNOSTICO <= 79 ~ "75-79 años",
      EDAD_DIAGNOSTICO >= 80 ~ "80 y más",
      TRUE ~ NA_character_
    )
  ) %>%
  mutate(ID_LOC_INDEC_RESIDENCIA = as.character(ID_LOC_INDEC_RESIDENCIA))

# opciones para los selectores globales
anios_disponibles <- sort(unique(base_eventos$ANIO_MINIMO))
deptos_disponibles <- sort(unique(base_eventos$DEPARTAMENTO_RESIDENCIA))
eventos_disponibles <- sort(unique(base_eventos$EVENTO))

# mapa -------------------------------------------------------------------------

shape_deptos <- st_read("archivos/santafe_deptos.shp")

shape_localidades <- st_read("archivos/localidadsantafe.shp") |>
  mutate(across(where(is.character), ~ iconv(., from = "latin1", to = "UTF-8")))

# poblacion --------------------------------------------------------------------

poblacion <- read_excel("archivos/poblacion_deptos.xlsx") 

# tabla base todos los depts ---------------------------------------------------

tabla_depos <- table(base_eventos$DEPARTAMENTO_RESIDENCIA) %>% 
  as.data.frame() %>%
  select(Var1) %>%
  rename("Departamento"="Var1")
