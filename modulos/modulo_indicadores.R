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
          title = "Total de casos",
          value = textOutput(ns("vb_total")),
          showcase = icon("list-ol")
        ),
        value_box(
          title = "Confirmados",
          value = textOutput(ns("vb_confirmados")),
          showcase = icon("circle-check") 
        ),
        # value_box( # aguanta bien hasta 3, después se desacomoda...
        #   title   = "Fallecidos",
        #   value   = textOutput(ns("vb_fallecidos")),
        #   showcase = icon("heart-pulse"),
        #   showcase_layout = "left center" 
        # ),
        value_box(
          title = "Fallecidos",
          value = textOutput(ns("vb_letalidad")),
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

moduloIndicadoresServer <- function(id, base_sin_filtro_depto,anios_seleccionados,evento_seleccionado) {
  moduleServer(id, function(input, output, session) {
    
    # value boxes --------------------------------------------------------------
    
    resumen <- reactive({
      calcular_resumen_general(base_sin_filtro_depto())
    })
    
    output$vb_total <- renderText({resumen()$total})
    
    output$vb_confirmados <- renderText({
      confirmados_porcentaje <- resumen()$porcentaje_confirmados
      confirmados_porcentaje_texto <- if (is.na(confirmados_porcentaje)) "—" else paste0(confirmados_porcentaje, "%")
      paste0(resumen()$confirmados, " (", confirmados_porcentaje_texto, ")")
    })
    
    #output$vb_fallecidos <- renderText({resumen()$fallecidos})
    
    output$vb_letalidad <- renderText({
      letalidad <- resumen()$letalidad
      letalidad_texto <- if (is.na(letalidad)) "—" else paste0(letalidad, "%")
      paste0(resumen()$fallecidos, " (", letalidad_texto, ")")
      })
    
    
    # Tabla ---------------------------------------------------------------------
    
    df_tabla <- reactive({
      req(evento_seleccionado())
      calcular_tabla_indicadores(base_sin_filtro_depto(), poblacion, anios_seleccionados(), evento_seleccionado())
    })
    
    output$tabla <- renderReactable({
      tabla_indicadores(df_tabla())
    })
    
    # Mapa ---------------------------------------------------------------------
    
    output$mapa <- renderLeaflet({
      mapa_deptos_indicadores(base_sin_filtro_depto(), shape_deptos)
    })
    
    return(df_tabla) 
  })
}
