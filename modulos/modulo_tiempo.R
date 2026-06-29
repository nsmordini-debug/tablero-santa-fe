# ui ---------------------------------------------------------------------------

moduloTiempoUI <- function(id) {
  ns <- NS(id)
  
  tagList(
    
    # Value boxes --------------------------------------------------------------
    div(
      class = "value-boxes",
      layout_columns(
        fill = FALSE,
        height = "100px",
        value_box(
          title = "Total de casos",
          value = textOutput(ns("vb_total")),
          showcase = icon("list-ol")
        ),
        value_box(
          title = "Incidencia total",
          value = textOutput(ns("vb_tasa")),
          showcase = icon("percent")
        ),
        value_box(
          title = "Período con mayor carga",
          value = textOutput(ns("vb_periodo_max")),
          showcase = icon("calendar-day")
        )
      )
    ),
    
    # fila con gráfico a la izq y opciones a la der ----------------------------
    layout_columns(
      col_widths = c(9, 3),
      card(
        card_header("Distribución temporal"),
        conditionalPanel(
          condition = "input.vista_semana == 'corredor'",
          ns = ns,
          plotlyOutput(ns("grafico_corredor"), height = "450px")
        ),
        conditionalPanel(
          condition = "input.vista_semana != 'corredor'",
          ns = ns,
          highchartOutput(ns("grafico_tiempo"), height = "450px")
        )
      ),
      card(
        card_header("Opciones gráfico"),
        radioButtons(
          inputId = ns("tipo_grafico"),
          label = "Tipo de gráfico",
          choices = c("Semana epidemiológica" = "semana", "Año" = "anio"),
          selected = "semana"
        ),
        conditionalPanel(
          condition = "input.tipo_grafico == 'semana' && output.un_solo_anio",
          ns = ns,
          uiOutput(ns("selector_vista_semana")) # uioutput porque se genera dinamicamente en server  
        ),
        radioButtons(
          inputId = ns("clasif_casos"),
          label = "Tipo de casos",
          choices = c("Total notificado" = "casos", "Confirmados" = "confirmados", "Probables" = "probables"),
          selected = "casos"
        )
      )
    )
  )
}

# server -----------------------------------------------------------------------

moduloTiempoServer <- function(id, base_filtrada, anios_seleccionados,base_sin_anio) {
  moduleServer(id, function(input, output, session) {
    
    ns <- session$ns
    
    # Value boxes --------------------------------------------------------------
    
    vb_tiempo <- reactive({
      calcular_vb_tiempo(
        base_filtrada(),
        input$tipo_grafico,
        poblacion,    
        anios_seleccionados()
      )
    })

    output$vb_total <- renderText({
      vb_tiempo()$total
    })
    
    output$vb_tasa <- renderText({
      vb_tiempo()$tasa
    })
    
    output$vb_periodo_max <- renderText({
      vb_tiempo()$periodo_max
    })
    
    
    # gráfico ------------------------------------------------------------------
    
    base_grafico <- reactive({
      if (input$tipo_grafico == "anio") base_sin_anio() else base_filtrada()
    })
    
    output$grafico_tiempo <- renderHighchart({
      
      validate(need(nrow(base_grafico()) > 0, "No hay casos para los filtros seleccionados."))
      
      req(input$vista_semana)
      req(input$vista_semana != "corredor")
      
      grafico_temporal(
        base_grafico(),
        input$tipo_grafico,
        input$clasif_casos,
        poblacion,
        anios_seleccionados(),
        input$vista_semana
      )
    })
    
    output$grafico_corredor <- renderPlotly({
      
      req(input$vista_semana == "corredor")
      
      validate(need(nrow(base_sin_anio()) > 0, "No hay casos para los filtros seleccionados."))
      
      corredor_endemico(
        base_sin_anio(),
        col_anio = "ANIO_MINIMO",
        col_semana = "SEPI_MINIMA",
        col_clasificacion = "CLASIFICACION",
        clasif_incluidas = c("CONFIRMADO","PROBABLE")
      )
    })
    
    
    # elementos dinámicos para la ui -------------------------------------------
    
    # para cuando se seleccione la opcion de gráfico por semanas (ver conditional panel en ui)
    # (cuando se selecciona tipo de gráfico por semanas, y un solo año, se muestra la opción de graficar por líneas
    # o por barras; si se selecciona más de un año, el gráfico por semanas siempre es de líneas para
    # que se puedan comparar todos los años seleccionados más claramente)
    
    output$un_solo_anio <- reactive({
      length(anios_seleccionados()) == 1
    })
    outputOptions(output, "un_solo_anio", suspendWhenHidden = FALSE)
    
    # para generar los radiobuttons de "Mostrar" dinámicamente según los otros inputs del usuario
    # (cuando se selecciona Tipo de gráfio Semana, solo se muestra opción para corredor endémico
    # si el año seleccionado es el más reciente, 2026 en este caso)
    
    output$selector_vista_semana <- renderUI({
      
      opciones <- c("Línea" = "lineas", "Barras" = "barras")
      
      if (length(anios_seleccionados()) == 1 &&
          anios_seleccionados()[1] == max(anios_disponibles)) {
        opciones <- c(opciones, "Corredor endémico" = "corredor")
      }
      
      radioButtons(
        inputId = ns("vista_semana"),
        label = "Mostrar",
        choices = opciones,
        selected = "lineas"
      )
    })
  })
}
