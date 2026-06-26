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
          inputId  = ns("tipo_grafico"),
          label    = "Tipo de gráfico",
          choices  = c("Semana epidemiológica" = "semana", "Año" = "anio"),
          selected = "semana"
        ),
        
        conditionalPanel(
          condition = "input.tipo_grafico == 'semana' && output.un_solo_anio",
          ns = ns,
          uiOutput(ns("selector_vista_semana"))   # <-- ahora es un placeholder
        ),
        
        radioButtons(
          inputId  = ns("clasif_casos"),
          label    = "Tipo de casos",
          choices  = c("Total notificado" = "casos", "Confirmados" = "confirmados", "Probables" = "probables"),
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
    
    resumen <- reactive({
      calcular_resumen_tiempo(
        base_filtrada(),
        input$tipo_grafico,
        poblacion,    
        anios_seleccionados()
      )
    })
    
    output$vb_total <- renderText({
      resumen()$total
    })
    
    output$vb_tasa <- renderText({
      resumen()$tasa
    })
    
    output$vb_periodo_max <- renderText({
      resumen()$periodo_max
    })
    
    # base según se eliga por año o semana
    base_activa <- reactive({
      if (input$tipo_grafico == "anio") base_sin_anio() else base_filtrada()
    })
    
    # para los avalus boxes
    resumen <- reactive({
      calcular_resumen_tiempo(base_activa(), input$tipo_grafico, poblacion, anios_seleccionados())
    })
    
    # para cuando se seleccione la opcion de gráfico por semanas (ver conditional panel en ui)
    output$un_solo_anio <- reactive({
      length(anios_seleccionados()) == 1
    })
    outputOptions(output, "un_solo_anio", suspendWhenHidden = FALSE)
    
    
    # render ui para generar los radiobuttons dinámicamente
    output$selector_vista_semana <- renderUI({
      
      opciones <- c("Comparar años (líneas)" = "lineas", "Un año (barras)" = "barras")
      
      if (length(anios_seleccionados()) == 1 &&
          anios_seleccionados()[1] == max(anios_disponibles)) {
        opciones <- c(opciones, "Corredor endémico" = "corredor")
      }
      
      radioButtons(
        inputId  = ns("vista_semana"),
        label    = "Mostrar",
        choices  = opciones,
        selected = "lineas"
      )
    })
    
    # grafico
    
    output$grafico_tiempo <- renderHighchart({
      req(input$vista_semana)
      req(input$vista_semana != "corredor")
      
      grafico_temporal(
        base_activa(),
        input$tipo_grafico,
        input$clasif_casos,
        poblacion,
        anios_seleccionados(),
        input$vista_semana
      )
    })
    
    # gráfico coredor
    output$grafico_corredor <- renderPlotly({
      req(input$vista_semana == "corredor")
      
      corredor_endemico(
        base_sin_anio(),
        col_anio = "ANIO_MINIMO",
        col_semana = "SEPI_MINIMA",
        col_clasificacion = "CLASIFICACION",
        clasif_incluidas = c("CONFIRMADO","PROBABLE")
      )
    })
    
  })
}
