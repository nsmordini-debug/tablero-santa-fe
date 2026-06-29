
# función para calcular valores para lso value boxes ------------------------------

calcular_value_boxes <- function(df) {
  
  total <- nrow(df)
  confirmados <- sum(df$CLASIFICACION=="CONFIRMADO")
  fallecidos <- sum(df$FALLECIDO == "SI")
  porcentaje_confirmados <- if (total > 0) round(confirmados/total * 100, 1) else NA
  letalidad <- if (confirmados > 0) round(fallecidos/confirmados * 100, 1) else NA
  
  list( 
    total = total,
    confirmados = confirmados,
    porcentaje_confirmados = porcentaje_confirmados,
    fallecidos = fallecidos,
    letalidad = letalidad
  )}


# función auxiliar para preparar el df de estimaciones poblacionales --------------
# (filtra los años seleccionados por el usuario y suma la población de los deptos)

preparar_poblacion <- function(pob_df, anios_seleccionados) {
  pob_df |>
    filter(anio %in% as.numeric(anios_seleccionados))|>
    group_by(nombre_depto) |>
    summarise(poblacion = sum(poblacion), .groups = "drop")
}


# función para armar la tabla de indicarores -----------------------------------
# (calcula los valores de cada columna para cada depto y para el total, y los une)

calcular_tabla_indicadores <- function(df, pob_df, anios_seleccionados, evento_seleccionado) {
  
  # filas deptos
  
  pob <- preparar_poblacion(pob_df, anios_seleccionados)
  
  por_depto <- df |>
    group_by(DEPARTAMENTO_RESIDENCIA) |>
    summarise(
      Total = n(),
      Confirmados = sum(CLASIFICACION == "CONFIRMADO", na.rm = TRUE),
      Probables = sum(CLASIFICACION == "PROBABLE", na.rm = TRUE),
      Fallecidos = sum(FALLECIDO == "SI", na.rm = TRUE),
      .groups = "drop"
    ) |>
    mutate(
      `% Positiv.` = if_else(Total > 0, round(Confirmados / Total * 100, 1), NA_real_),
      `% Letalidad` = if_else(Confirmados > 0, round(Fallecidos / Confirmados * 100, 1), NA_real_)
    ) |>
    left_join(pob, by = c("DEPARTAMENTO_RESIDENCIA" = "nombre_depto")) |>
    mutate(`Tasa x 100.000 hab.` = round(Confirmados / poblacion * 100000, 1)) |>
    select(-poblacion) |>
    arrange(DEPARTAMENTO_RESIDENCIA)
  
  # fila total
  
  pob_total <- sum(pob$poblacion)
  
  fila_total <- df |>
    summarise(
      Total = n(),
      Confirmados = sum(CLASIFICACION == "CONFIRMADO", na.rm = TRUE),
      Probables = sum(CLASIFICACION == "PROBABLE", na.rm = TRUE),
      Fallecidos = sum(FALLECIDO == "SI", na.rm = TRUE)
    ) |>
    mutate(
      `% Positiv.` = if_else(Total > 0, round(Confirmados / Total * 100, 1), NA_real_),
      `% Letalidad` = if_else(Confirmados > 0, round(Fallecidos / Confirmados * 100, 1), NA_real_),
      Departamento = "TOTAL",
      `Tasa x 100.000 hab.` = round(Confirmados / pob_total * 100000, 1),
      .before = everything()
    )
  
  # union
  
  por_depto_completo <- tabla_depos |>
    left_join(por_depto, by = c("Departamento" = "DEPARTAMENTO_RESIDENCIA"))
  
  tabla_final <- bind_rows(por_depto_completo, fila_total) |>
    mutate(across(where(is.numeric), ~ replace_na(., 0)))
  
  # selección de columnas según el grupo del evento (ver en global)
  
  if (evento_seleccionado %in% eventos_sin_confirmacion) {
    tabla_final <- tabla_final |>
      select(Departamento, Total, Fallecidos, `% Letalidad`, `Tasa x 100.000 hab.`)
  }
  tabla_final
}


# función para crear el reactable a partir de la tabla armada con la funcion anterior---------- 

tabla_indicadores <- function(df_tabla) {
  
  # formato para todas las columnas posibles
  columnas_posibles <- list(
    
    Departamento = colDef(
      name = "Departamento",
      minWidth = 140,
      sticky = "left",
      style = function(value) {
        if (value == "TOTAL") list(fontWeight = "bold") else NULL
      },
      cell = function(value) {
        if (value == "TOTAL") tags$b(value) else value
      }
    ),
    
    Total = colDef(align = "center"),
    
    Confirmados = colDef(name = "Casos confirm.", align = "center"),
    
    Probables = colDef(name = "Casos probab.", align = "center"),
    `% Positiv.` = colDef(
      align = "center",
      cell = function(value) {
        if (is.na(value)) "—" else paste0(value, "%")
      }),
    
    Fallecidos = colDef(align = "center"),
    
    `% Letalidad` = colDef(
      align = "center",
      cell = function(value) {
        if (is.na(value)) "—" else paste0(value, "%")
      }),
    
    `Tasa x 100.000 hab.` = colDef(
      align = "center",
      name = "Tasa x 100.000 hab.",
      cell = function(value) {
        if (is.na(value)) "—" else value
      }
    )
  )
  
  # se toman solo las que existen según el grupo del evento
  columnas_a_usar <- columnas_posibles[names(columnas_posibles) %in% names(df_tabla)]
  
  # objeto final reactable que devuelve la función 
  reactable(
    df_tabla,
    striped  = TRUE,
    highlight = TRUE,
    bordered = FALSE,
    compact = TRUE,
    defaultPageSize = 25,
    columns = columnas_a_usar
  )
}


# función para armar el mapa ---------------------------------------------------

mapa_deptos_indicadores <- function(df, shape) {
  
  # casos por depto
  casos_depto <- df |>
    group_by(DEPARTAMENTO_RESIDENCIA) |>
    summarise(casos = sum(CLASIFICACION=="CONFIRMADO"), .groups = "drop")
  
  #browser()
  
  # unión al shp
  shape_datos <- shape |>
    left_join(casos_depto, by = c("nam" = "DEPARTAMENTO_RESIDENCIA"))|>
    mutate(casos = replace_na(casos, 0))
  
  # paleta de color (al final no la usamos acá, la dejo por las dudas)
  pal <- colorNumeric(
    palette = "YlOrRd",
    domain  = shape_datos$casos,
    na.color = "#cccccc"
  )
  
  # mapa
  leaflet(shape_datos) |>
    addTiles() |>
    addPolygons(
      #fillColor = ~pal(casos),
      fillColor =  ~ifelse(casos == 0, "#cccccc", "#BD0026"),
      fillOpacity = 0.7,
      color = "black",
      weight= 1.5,
      label = ~paste0(nam, ": ",ifelse(casos == 0, "Sin casos", paste0(casos, ifelse(casos == 1, " caso", " casos")))),
      labelOptions = labelOptions(style = list("font-size" = "13px"), direction = "auto")
    ) 
  # |>
  #   addLegend(
  #     pal      = pal,
  #     values   = ~casos,
  #     title    = "Casos",
  #     position = "bottomright"
  #   )
  
}
