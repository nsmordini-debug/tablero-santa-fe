
# Value boxes ------------------------------------------------------------------

calcular_resumen_lugar <- function(df, pob_df, anios_sel, depto_sel,shape_locs) {
  
  total <- nrow(df)
  confirmados <- sum(df$CLASIFICACION=="CONFIRMADO")
  
  # tasa 
  pob <- preparar_poblacion(pob_df, anios_sel) # le queda la función de haberla usado en indicadores
  pob_total <- sum(pob$poblacion)
  tasa <- round(confirmados / pob_total * 100000, 1)
  
  # mayor carga
  if (is.null(depto_sel)) {
    mayor_carga <- df |>
      group_by(DEPARTAMENTO_RESIDENCIA) |>
      summarise(n = n(), .groups = "drop") |>
      slice_max(n, n = 1) |>
      mutate(label = paste0(DEPARTAMENTO_RESIDENCIA, " (", n, " casos)")) |>
      pull(label)
    titulo_max <- "Depto. con mayor carga"
  } else {
    mayor_carga <- df |>
      left_join(shape_locs, by =c("ID_LOC_INDEC_RESIDENCIA" = "codigo_ase"))|>
      #browser()
      group_by(nombre_geo) |>
      summarise(n = n(), .groups = "drop") |>
      slice_max(n, n = 1) |>
      mutate(label = paste0(nombre_geo, " (", n, " casos)")) |>
      pull(label)
    titulo_max <- "Localidad con mayor carga"
  }
  
  list(
    total = total,
    tasa = paste0(tasa, " por 100.000 hab."),
    mayor_carga = mayor_carga,
    titulo_max = titulo_max
  )
}

# mapa x deptos ------------------------------------------------------------------

# mapa_provincia <- function(df, shape_deptos, clasif_casos) {
#   
#   casos_depto <- df |>
#     group_by(DEPARTAMENTO_RESIDENCIA) |>
#     summarise(
#       casos = n(),
#       confirmados = sum(CLASIFICACION=="CONFIRMADO"),
#       probables = sum(CLASIFICACION=="PROBABLE"),
#       .groups = "drop"
#     )
#   
#   shape_datos <- shape_deptos |>
#     left_join(casos_depto, by = c("nam" = "DEPARTAMENTO_RESIDENCIA")) |>
#     mutate(mostrar_valor = switch(clasif_casos,
#                                   casos = casos,
#                                   confirmados = confirmados,
#                                   probables = probables
#     )
#   )
#   
#   #browser()
#   
#   pal <- colorNumeric(
#     palette  = "YlOrRd",
#     domain   = shape_datos$mostrar_valor,
#     na.color = "#cccccc"
#   )
#   
#   leaflet(shape_datos) |>
#     addTiles() |>
#     addPolygons(
#       fillColor = ~pal(mostrar_valor),
#       fillOpacity = 0.7,
#       color = "black",
#       weight = 1.5,
#      label = ~paste0(nam, ": ", ifelse(is.na(mostrar_valor), "Sin casos", paste0(mostrar_valor, " casos"))),
#       labelOptions = labelOptions(
#         style = list("font-size" = "13px"),
#         direction = "auto"
#       )
#     ) #|>
#   # addLegend(
#   #   pal= pal,
#   #   values   = ~mostrar_valor,
#   #   title = titulo,
#   #   position = "bottomright"
#   # )
# }

mapa_provincia <- function(df, shape_deptos, clasif_casos, mostrar_como, pob_df, anios_sel) {
  
  casos_depto <- df |>
    group_by(DEPARTAMENTO_RESIDENCIA) |>
    summarise(
      casos= n(),
      confirmados = sum(CLASIFICACION == "CONFIRMADO", na.rm = TRUE),
      probables = sum(CLASIFICACION == "PROBABLE", na.rm = TRUE),
      .groups = "drop"
    )
  
  pob <- preparar_poblacion(pob_df, anios_sel)
  
  shape_datos <- shape_deptos |>
    left_join(casos_depto, by = c("nam" = "DEPARTAMENTO_RESIDENCIA")) |>
    left_join(pob, by = c("nam" = "nombre_depto")) |>
    mutate(
      casos = replace_na(casos, 0),
      confirmados = replace_na(confirmados, 0),
      probables = replace_na(probables, 0),
      numero = switch(clasif_casos,
                           casos = casos,
                           confirmados = confirmados,
                           probables = probables),
      tasa = round(numero / poblacion * 100000, 1),
      mostrar_valor = if (mostrar_como == "tasa") tasa else numero
    )
  
  titulo_clasif_casos <- switch(clasif_casos,
                           casos = "Total notificado",
                           confirmados = "Confirmados",
                           probables = "Probables"
  )
  sufijo <- if (mostrar_como == "tasa") " x 100.000 hab." else " casos"
  
  pal <- colorNumeric(
    palette = "YlOrRd",
    domain = shape_datos$mostrar_valor,
    na.color = "#cccccc"
  )
  
  leaflet(shape_datos) |>
    addTiles() |>
    addPolygons(
      fillColor = ~ifelse(mostrar_valor == 0, "#bdbdbd", pal(mostrar_valor)),
      fillOpacity = 0.7,
      color = "black",
      weight = 1.5,
      label = ~paste0(nam, ": ", ifelse(mostrar_valor==0, "Sin casos",paste0(mostrar_valor, sufijo))),
      labelOptions = labelOptions(
        style = list("font-size" = "13px"),
        direction = "auto"
      )
    ) |>
    addLegend(
      pal = pal,
      values = ~mostrar_valor,
      title = paste0(titulo_clasif_casos, if (mostrar_como == "tasa") " (tasa)" else ""),
      position = "bottomright"
    )
}

# mapa x localidades -------------------------------------------------------------

mapa_departamento <- function(df, shape_deptos, shape_locs, depto_sel, clasif_casos) {
  
  shape_depto <- shape_deptos |>
    filter(nam == depto_sel)
  
  shape_locs_depto <- shape_locs |>
    filter(nombre_dep == depto_sel) |>
    st_drop_geometry() |>
    mutate(across(where(is.character), ~ iconv(., to = "UTF-8", sub = "")))
  
  casos_loc <- df |>
    group_by(ID_LOC_INDEC_RESIDENCIA) |>
    summarise(
      casos = n(),
      confirmados = sum(CLASIFICACION=="CONFIRMADO"),
      probables = sum(CLASIFICACION=="PROBABLE"),
      .groups = "drop"
    )
  
  shape_locs_datos <- shape_locs_depto |>
    left_join(
      casos_loc,
      by = c("codigo_ase" = "ID_LOC_INDEC_RESIDENCIA")
    ) |>
    mutate(
      casos = replace_na(casos, 0),
      confirmados = replace_na(confirmados, 0),
      probables = replace_na(probables, 0),
      mostrar_valor = switch(clasif_casos,
                             casos = casos,
                             confirmados = confirmados,
                             probables = probables
      ),
      longitud_g = as.numeric(longitud_g),
      latitud_gr = as.numeric(latitud_gr)
    )
  
  print(range(shape_locs_datos$mostrar_valor))
  
  pal <- colorNumeric(
    "YlOrRd",
    domain = shape_locs_datos$mostrar_valor,
    na.color = "#cccccc"
  )
  
  leaflet() |>
    addTiles() |>
    addPolygons(
      data = shape_depto,
      fillColor = "#d0d0d0",
      fillOpacity = 0.5,
      color = "#555555",
      weight = 1.5
    ) |>
    addCircleMarkers(
      data = shape_locs_datos,
      lng = ~longitud_g,
      lat = ~latitud_gr,
      radius = 8,
      fillColor = ~ifelse(mostrar_valor == 0, "#bdbdbd", pal(mostrar_valor)),
      fillOpacity = 0.8,
      color = "#555555",
      weight = 1.5,
      label = ~paste0(nombre_geo, ": ", ifelse(mostrar_valor==0, "Sin casos", paste0(mostrar_valor, " casos"))),
      labelOptions = labelOptions(
        style = list("font-size" = "13px"),
        direction = "auto"
      )
    ) 
  # |>
  #   addLegend(
  #     pal = pal,
  #     values = shape_locs_datos$mostrar_valor,
  #     title = if (clasif_casos == "casos") "Casos" else "Confirmados",
  #     position = "bottomright"
  #   )
}