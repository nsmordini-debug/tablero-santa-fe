
# Preparación del dataframe, agrupando x semana o año --------------------------

preparar_serie_temporal <- function(df, tipo_grafico) {
  
  columna_periodo <- switch(tipo_grafico, 
                  semana = "SEPI_MINIMA", 
                  anio = "ANIO_MINIMO")
  
  max_semana <- max(max(df$SEPI_MINIMA, na.rm = TRUE), 52) # ver si hay una mejor forma...
  
  rango_periodo <- if (tipo_grafico == "semana") 1:max_semana else anios_disponibles
  
  df |>
    group_by(periodo = .data[[columna_periodo]]) |>
    summarise(
      casos = n(),
      confirmados = sum(CLASIFICACION =="CONFIRMADO",na.rm = TRUE),
      probables = sum(CLASIFICACION == "PROBABLE", na.rm = TRUE),
      .groups = "drop") |> 
    complete(periodo = rango_periodo,
             fill = list(casos = 0, confirmados = 0, probables = 0)) |>
    arrange(periodo)
}

# Gráfico ----------------------------------------------------------------------

grafico_temporal <- function(df, tipo_grafico, clasif_casos, pob_df, anios_sel, vista_semana = "lineas") {
  
  etiq_eje_x <- switch(tipo_grafico, semana = "Semana epidemiológica", anio = "Año")
  
  # gráfico de barras por año
  
  if (tipo_grafico == "anio") {
    
    df_serie <- preparar_serie_temporal(df, tipo_grafico)
    
    valores <- switch(clasif_casos,
                      casos = df_serie$casos,
                      confirmados = df_serie$confirmados,
                      probables = df_serie$probables
    )
    
    label_y <- switch(clasif_casos, casos = "Total notificado", confirmados = "Confirmados", probables = "Probables")
    
    highchart() |>
      hc_chart(type = "column") |>
      hc_xAxis(categories = as.character(df_serie$periodo),title = list(text = etiq_eje_x)) |>
      hc_yAxis(title = list(text = label_y), min = 0) |>
      hc_add_series(name = label_y, data = valores, color = "#4A7FB5", showInLegend = FALSE) |>
      hc_tooltip(
        formatter = JS("function() {
          return '<b>' + this.point.category + '</b><br/>' +
                 this.series.name + ': <b>' + this.y + '</b>'
        }")
      ) |>
      hc_plotOptions(column = list(groupPadding = 0.05, pointPadding = 0))
    
  } else if (vista_semana == "barras" && length(anios_sel) == 1) {
    
    
    # gráfico de barras para semanas epidemiológicas (único año) 
    
    a <- anios_sel[1] 
    
    semana_actual <- as.integer(format(Sys.Date(), "%V"))
    anio_actual   <- as.integer(format(Sys.Date(), "%Y"))
    
    tope_anio <- if (a == anio_actual) {
      semana_actual
    } else {
      max(max(df$SEPI_MINIMA[df$ANIO_MINIMO == a], na.rm = TRUE), 52)
    }
    
    df_anio <- df |>
      filter(ANIO_MINIMO == a) |> 
      group_by(periodo = SEPI_MINIMA) |>
      summarise(
        casos= n(),
        confirmados = sum(CLASIFICACION == "CONFIRMADO", na.rm = TRUE),
        probables = sum(CLASIFICACION == "PROBABLE", na.rm = TRUE),
        .groups = "drop"
      ) |>
      complete(periodo = 1:tope_anio, fill = list(casos = 0, confirmados = 0)) |>
      arrange(periodo)
    
    valores <- switch(clasif_casos,
                      casos = df_anio$casos,
                      confirmados = df_anio$confirmados,
                      probables = df_anio$probables
    )
    label_y <- switch(clasif_casos, casos = "Total notificado", confirmados = "Confirmados", probables = "Probables")
    
    highchart() |>
      hc_chart(type = "column") |>
      hc_xAxis(categories = as.character(1:tope_anio), title = list(text = etiq_eje_x)) |>
      hc_yAxis(title = list(text = label_y), min = 0) |>
      hc_add_series(name = as.character(a), data = valores,
                    color = "#4A7FB5", showInLegend = FALSE) |>
      hc_tooltip(
        formatter = JS("function() {
          return 'Semana <b>' + this.point.category + '</b><br/>' +
                 this.series.name + ': <b>' + this.y + '</b>'
        }")
      ) |>
      hc_plotOptions(column = list(groupPadding = 0.05, pointPadding = 0))
    
  } else {
    
    # gráfico de líneas por semana epidemiológica
    
    anios_presentes <- sort(unique(df$ANIO_MINIMO))
    tope <- max(max(df$SEPI_MINIMA, na.rm = TRUE), 52)
    label_y <- switch(clasif_casos, casos = "Total notificado", confirmados = "Confirmados", probables = "Probables")
    
    hc <- highchart() |>
      hc_chart(type = "line") |>
      hc_xAxis(categories = as.character(1:tope), title = list(text = etiq_eje_x)) |>
      hc_yAxis(title = list(text = label_y), min = 0) |>
      hc_tooltip(formatter = JS("function() {
      return 'Semana <b>' + this.point.category + '</b><br/>' + this.series.name + ': <b>' + this.y + '</b>'
    }"))
    
    semana_actual <- as.integer(format(Sys.Date(), "%V"))
    anio_actual   <- as.integer(format(Sys.Date(), "%Y"))
    
    for (a in anios_presentes) {
      tope_anio <- if (a == anio_actual) semana_actual else max(max(df$SEPI_MINIMA[df$ANIO_MINIMO == a], na.rm = TRUE), 52)
      
      df_anio <- df |>
        filter(ANIO_MINIMO == a) |>
        group_by(periodo = SEPI_MINIMA) |>
        summarise(
          casos = n(),
          confirmados = sum(CLASIFICACION == "CONFIRMADO", na.rm = TRUE),
          probables = sum(CLASIFICACION == "PROBABLE", na.rm = TRUE),
          .groups = "drop"
        ) |>
        complete(periodo = 1:tope_anio, fill = list(casos = 0, confirmados = 0, probables = 0)) |>
        arrange(periodo)
      
      valores <- switch(clasif_casos,
                        casos = df_anio$casos,
                        confirmados = df_anio$confirmados,
                        probables =df_anio$probables
      )
      
      hc <- hc |> hc_add_series(name = as.character(a), data = valores)
    }
    hc
  }
}

# value boxes ------------------------------------------------------------------

calcular_resumen_tiempo <- function(df, tipo_grafico, pob_df, anios_sel) {
  
  df_serie <- preparar_serie_temporal(df, tipo_grafico)
  
  total <- sum(df_serie$casos)
  
  # Período con mayor carga
  fila_max <- df_serie |> filter(casos == max(casos)) |> slice(1) # ver cómo manenejar empates...
  periodo_max <- paste0(fila_max$periodo, " (", fila_max$casos, " casos)")
  
  # Tasa 
  pob <- preparar_poblacion(pob_df, anios_sel)
  pob_total <- sum(pob$poblacion)
  confirmados_total <- sum(df_serie$confirmados)
  tasa <- round(confirmados_total / pob_total * 100000, 1)
  
  list(
    total = total,
    periodo_max = periodo_max,
    tasa = paste0(tasa, "por 100.000 hab.")
  )
}
