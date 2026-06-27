
# para value boxes -------------------------------------------------------------
# (llevarlos a una sola función dp para que quede parejo con los otros)

calcular_mediana_edad <- function(df) {
  median(df$EDAD_DIAGNOSTICO, na.rm = TRUE)
}

calcular_razon_hm <- function(df) {
  hombres <- sum(df$SEXO == "M", na.rm = TRUE)
  mujeres <- sum(df$SEXO == "F", na.rm = TRUE)
  if (mujeres == 0) return("N/D")
  round(hombres / mujeres, 2)
}

calcular_rango_etario <- function(df) {
  df |>
    group_by(GRUPO)|>
    summarise(nro=n())|>
    filter(nro == max(nro))|>
    select(GRUPO)|> pull()
}

# para gráficos ----------------------------------------------------------------

orden_grupos <- c(
  "Menores de 1 año", "1-4 años", "5-9 años", "10-14 años","15-19 años", "20-24 años", "25-29 años", "30-34 años",
  "35-39 años", "40-44 años", "45-49 años", "50-54 años","55-59 años", "60-64 años", "65-69 años", "70-74 años","75-79 años", "80 y más"
)

# gráfico de pirámide

grafico_sexo_edad <- function(df, mostrar_como) {
  
  # preparación del dataframe para este grádfico
  df_sexo_edad <- df |>
    filter(SEXO %in% c("F", "M"), !is.na(EDAD_DIAGNOSTICO)) |>
    mutate(GRUPO = factor(GRUPO, levels = orden_grupos)) |>
    group_by(GRUPO, SEXO) |> # GRUPO se crea en global, para tener grupos quinquenales, a diferencia de GRUPO_ETARIO que ya estaba en la base
    summarise(nro = n(), .groups = "drop")|>
    complete(GRUPO, SEXO = c("F", "M"), fill = list(nro = 0)) 
  
  #browser()
  
  if (mostrar_como == "porcentaje") {
    total <- sum(df_sexo_edad$nro)
    df_sexo_edad <- df_sexo_edad |>
      mutate(nro = round(nro / total * 100, 1))
  }
  
  # pivot para tener una columna por sexo
  df_wide <- df_sexo_edad |>
    pivot_wider(names_from  = SEXO,
                values_from = nro,
                values_fill = 0) |>
    arrange(GRUPO)  
  
  grupos <- as.character(df_wide$GRUPO)
  mujeres <- df_wide$F
  varones <- df_wide$M * -1   # negativos para ir a la izquierda
  
  label_x <- if (mostrar_como == "porcentaje") "%" else "Casos"
  
  highchart() |>
    #hc_size(height = 700) |>
    hc_chart(type = "bar") |>
    hc_xAxis(
      categories = grupos,
      reversed = FALSE, # grupos de menor a mayor de abajo hacia arriba
      title = list(text = "Grupo etario")
    ) |>
    hc_yAxis(
      title = list(text = label_x),
      labels = list(formatter = JS("function() { return Math.abs(this.value) }"))
    ) |>
    hc_add_series(
      name = "Mujeres",
      data = mujeres,
      color = "#E05C7A"
    ) |>
    hc_add_series(
      name = "Varones",
      data = varones,
      color = "#4A90D9"
    ) |>
    hc_tooltip(
      formatter = JS("function() {
        return '<b>' + this.series.name + '</b><br/>' +
               this.point.category + ': <b>' + Math.abs(this.y) + '</b>'
      }")
    ) |>
    hc_plotOptions(
      series = list(
        stacking = "normal",
        grouping = FALSE,
        pointPadding = 0,    
        groupPadding = 0.1
      )
    ) |>
    hc_legend(
      enabled = TRUE,
      align = "center"
    ) |>
    hc_title(text = "Distribución por sexo y edad")
}


# gráfico de barras

grafico_edad <- function(df, mostrar_como) {
  
  df_edad <- df |>
    mutate(GRUPO = factor(GRUPO, levels = orden_grupos)) |> 
    filter(!is.na(EDAD_DIAGNOSTICO)) |>
    group_by(GRUPO) |> 
    summarise(nro = n(), .groups = "drop") |>
    complete(GRUPO, fill = list(nro = 0)) |>
    arrange(GRUPO)
  
  if (mostrar_como == "porcentaje") {
    df_edad <- df_edad |>
      mutate(nro = round(nro / sum(nro) * 100, 1))
  }
  
  label_y <- if (mostrar_como == "porcentaje") "%" else "Casos"
  
  highchart() |>
    hc_chart(type = "column") |>
    hc_xAxis(
      categories = as.character(df_edad$GRUPO),
      title = list(text = "Grupo etario")
    ) |>
    hc_yAxis(
      title = list(text = label_y)
    ) |>
    hc_add_series(
      name = "Casos",
      data = df_edad$nro,
      color = "#6A9E7F",
      showInLegend = FALSE
    ) |>
    hc_tooltip(
      formatter = JS("function() {
        return '<b>' + this.point.category + '</b><br/>' +
               'Casos: <b>' + this.y + '</b>'
      }")
    ) |>
    hc_plotOptions(
      column = list(
        groupPadding = 0.05,
        pointPadding = 0
      )
    ) |>
    hc_title(text = "Distribución por edad")
}
