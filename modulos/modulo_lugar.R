# ui ---------------------------------------------------------------------------

moduloLugarUI <- function(id) {
  ns <- NS(id)
  
  tagList(
    
    # value boxes ---------------------------------------------------------------
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
          title = textOutput(ns("vb_titulo_max")),
          value = textOutput(ns("vb_mayor_carga")),
          showcase = icon("location-dot")
        )
      )),
    
    # mapa ---------------------------------------------------------------------
    layout_columns(
      col_widths = c(9,3),
      
      card(
        card_header(textOutput(ns("titulo_mapa"))),
        leafletOutput(ns("mapa"), height = "500px")
      ),
      
      card(
        card_header("Opciones gráfico"),
        radioButtons(
          inputId = ns("clasif_casos"),
          label = "Tipo de casos",
          choices  = c("Casos totales" = "casos", "Casos confirmados" = "confirmados", "Casos probables"="probables"),
          selected = "casos"
        ),
        # radioButtons(
        #   inputId = ns("mostrar_como"),
        #   label = "Mostrar como",
        #   choices = c("Número de casos" = "numero", "Tasa x 100.000 hab." = "tasa"),
        #   selected = "numero"
        # )
        conditionalPanel(
          condition = "output.vista_provincial",
          ns = ns,
          radioButtons(
            inputId = ns("mostrar_como"),
            label = "Mostrar como",
            choices = c("Número de casos" = "numero","Tasa x 100.000 hab." = "tasa"),
            selected = "numero"
          )
        )
      )
    )
  )
}

# server -----------------------------------------------------------------------

moduloLugarServer <- function(id, base_filtrada, depto_seleccionado, anios_seleccionados) {
  moduleServer(id, function(input, output, session) {
    
    # Value boxes --------------------------------------------------------------
    
    # Resumen 
    resumen <- reactive({
      calcular_resumen_lugar(
        base_filtrada(),
        poblacion,
        anios_seleccionados(),
        depto_seleccionado(),
        shape_localidades
      )
    })
    
    output$vb_total <- renderText({ resumen()$total })
    
    output$vb_tasa <- renderText({ resumen()$tasa })
    
    output$vb_mayor_carga <- renderText({ resumen()$mayor_carga })
    
    output$vb_titulo_max <- renderText({ resumen()$titulo_max })
    
    vista_provincial <- reactive({
      is.null(depto_seleccionado())
    })
    
    # Título dinámico del mapa
    output$titulo_mapa <- renderText({
      if (is.null(depto_seleccionado())) {
        "Distribución provincial por departamento"
      } else {
        paste("Localidades —", depto_seleccionado())
      }
    })
   
    
    # Mapa ----------------------------------------------------------------------

    output$mapa <- renderLeaflet({
      depto <- depto_seleccionado()
      base  <- base_filtrada()
      req(nrow(base) > 0)
      
      tryCatch({
        if (is.null(depto)) {
          mapa_provincia(base, shape_deptos, input$clasif_casos, input$mostrar_como, poblacion, anios_seleccionados())
        } else {
          mapa_departamento(base, shape_deptos, shape_localidades, depto, input$clasif_casos)
        }
      }, error = function(e) {
        print(e)
        leaflet() |> addTiles()
      })
    })
    
    # output dinámico para mostrar o no el input de qué mostrar ----------------
    
    output$vista_provincial <- reactive({
      is.null(depto_seleccionado())
    })
    outputOptions(output, "vista_provincial", suspendWhenHidden = FALSE)
    
  })
}
