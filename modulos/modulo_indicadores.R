# ui ---------------------------------------------------------------------------

moduloIndicadoresUI <- function(id) {
  ns <- NS(id)
  
  tagList(
    
    # fila con los value boxes -------------------------------------------------
    div( # dentro de un div par poder asignarles a todos las clases definida en bs_add_rules, en la ui ppal
      class = "value-boxes",
      layout_columns(
        height = "100px", 
        value_box(
          title   = "Total de casos",
          value   = textOutput(ns("vb_total")),
          showcase = icon("list-ol")
        ),
        value_box(
          title   = "Confirmados",
          value   = textOutput(ns("vb_confirmados")),
          showcase = icon("circle-check") 
        ),
        # value_box( # aguanta bien hasta 3, después se desacomoda...
        #   title   = "Fallecidos",
        #   value   = textOutput(ns("vb_fallecidos")),
        #   showcase = icon("heart-pulse"),
        #   showcase_layout = "left center" 
        # ),
        value_box(
          title   = "Fallecidos",
          value   = textOutput(ns("vb_letalidad")),
          showcase = icon("heart-pulse")#percent
        )
      )
    ),
    
    # fila con tabla y mapa ----------------------------------------------------
    layout_columns(
      col_widths = c(8, 4),
      
      card(
        card_header("Indicadores por departamento"),
        reactableOutput(ns("tabla"))
      ),
      
      card(
        card_header("Departamentos con casos confirmados"),
        leafletOutput(ns("mapa"), height = "1000px")
      )
    )
  )
}

# server -----------------------------------------------------------------------

moduloIndicadoresServer <- function(id, base_sin_filtro_depto,anios_seleccionados) {
  moduleServer(id, function(input, output, session) {
    
    # value boxes --------------------------------------------------------------
    
    resumen <- reactive({
      calcular_resumen_general(base_sin_filtro_depto())
    })
    
    output$vb_total <- renderText({resumen()$total})
    
    output$vb_confirmados <- renderText({
      paste0(resumen()$confirmados, " (", resumen()$porcentaje_confirmados, "%)")
    })
    
    #output$vb_fallecidos <- renderText({resumen()$fallecidos})
    
    output$vb_letalidad <- renderText({
      paste0(resumen()$fallecidos," (", resumen()$letalidad, "%)")
      })
    
    
    # Tabla ---------------------------------------------------------------------
    
    df_tabla <- reactive({
      calcular_tabla_indicadores(base_sin_filtro_depto(), poblacion, anios_seleccionados())
    })
    
    output$tabla <- renderReactable({
      tabla_indicadores(df_tabla())
    })
    
    # Mapa ---------------------------------------------------------------------
    
    output$mapa <- renderLeaflet({
      mapa_deptos_indicadores(base_sin_filtro_depto(), shape_deptos)
    })
  })
}
