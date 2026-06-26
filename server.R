
server <- function(input, output, session) {
  
  # reactive global ------------------------------------------------------------
  # (dataframe filtrado según los inputs del sidebar evento + año + depto)
  
  base_filtrada <- reactive({
    
    df <- base_eventos
    
    # filtro evento
    df <- df |> filter(EVENTO == input$filtro_evento)
    
    # filtro año
    if (!is.null(input$filtro_anio)) {
      df <- df |> filter(ANIO_MINIMO %in% input$filtro_anio)
    }
    
    # filtro departamento
    if (!is.null(input$filtro_depto)) {
      df <- df |> filter(DEPARTAMENTO_RESIDENCIA %in% input$filtro_depto)
    }
    
    df
  })
  
  # reactives para pestañas específicas  -------------------------------------
  # (dataframe filtrado según los inputs disponibles en cada pestaña)
  
  # indicadores (sin filtro deptos)
  base_sin_filtro_depto <- reactive({
    df <- base_eventos
    
    if (!is.null(input$filtro_anio)) {
      df <- df |> filter(ANIO_MINIMO %in% input$filtro_anio)
    }
    
    if (!is.null(input$filtro_evento)) {
      df <- df |> filter(EVENTO == input$filtro_evento)
    }
    
    df
  })
  
  # tiempo (sin filtro años, para el gráfico de casos x año)
  base_sin_anio <- reactive({
    df <- base_eventos
    
    if (!is.null(input$filtro_depto) && !("TODOS" %in% input$filtro_depto)) {
      df <- df |> filter(DEPARTAMENTO_RESIDENCIA %in% input$filtro_depto)
    }
    
    if (!is.null(input$filtro_evento)) {
      df <- df |> filter(EVENTO == input$filtro_evento)
    }
    
    df
  })
  
  # reactive auxiliares ----------------------------------------------------------
  #(porque los inputs globales no se pueden pasar como tales a los módulos)
  
  # para pestaña lugar
  depto_seleccionado <- reactive({
    deptos <- input$filtro_depto
    if (is.null(deptos) || length(deptos) != 1) { 
      return(NULL) # y se siguen considerando todos       
    }
    deptos # nombre del depto único seleccionado
  })
  
  # para pestañas indicadores, lugar y tiempo
  anios_seleccionados <- reactive({
    as.numeric(input$filtro_anio)
  })
  
  # para indicadores
  evento_seleccionado <- reactive({
    as.character(input$filtro_evento)
  })
  
  
  # observers ------------------------------------------------------------------
  
  # para ocultar input de departamento en pestaña indicadores
  observe({
    if (input$navbar == "Indicadores") {
      shinyjs::hide("filtro_depto")
    } else {
      shinyjs::show("filtro_depto")
    }
  })
  
  
  # para ocultar el sidebar en la pestaña "acerca de"
  
  observe({
    if (input$navbar == "Acerca de") {
      shinyjs::addClass(selector = ".sidebar", class = "oculto")
    } else {
      shinyjs::removeClass(selector = ".sidebar", class = "oculto")
    }
  })
  
  observe({
    if (input$navbar == "Acerca de") {
      toggle_sidebar("sidebar", open = FALSE, session = session)
    } else {
      toggle_sidebar("sidebar", open = TRUE, session = session)
    }
  })
  
  # para que solo se permita seleccionar un departamento o todos juntos (pero no varios Esto para la pestaña lugar)
  observe({
    if (input$navbar == "Lugar") {
      # Si hay selección parcial, resetear a todos
      if (length(input$filtro_depto) > 1 && 
          length(input$filtro_depto) < length(deptos_disponibles)) {
        updatePickerInput(session, "filtro_depto", selected = deptos_disponibles)
      }
      # Restringir a máximo 1
      updatePickerInput(session, "filtro_depto",
                        options = list(
                          `actions-box`          = TRUE,
                          `select-all-text`      = "Seleccionar todos",
                          `deselect-all-text`    = "Deseleccionar todos",
                          `none-selected-text`   = "— Sin filtro (todos) —",
                          `selected-text-format` = "count > 2",
                          `count-selected-text`  = "{0} seleccionados",
                          `max-options`          = 1,
                          `max-options-text`     = "Seleccioná un departamento o todos"
                        ))
    } else {
      # Restaurar sin restricción al salir de Lugar (para que no cause problemas en las otras pestañas)
      updatePickerInput(session, "filtro_depto",
                        options = list(
                          `actions-box`          = TRUE,
                          `select-all-text`      = "Seleccionar todos",
                          `deselect-all-text`    = "Deseleccionar todos",
                          `none-selected-text`   = "— Sin filtro (todos) —",
                          `selected-text-format` = "count > 2",
                          `count-selected-text`  = "{0} seleccionados"
                        ))
    }
  })
  
  # para armar los labels de los inputs de las distintas pestañas --------------
  
  observe({
    pestaña <- input$navbar
    
    # Año 
    texto_anio <- switch(pestaña,
                         "Indicadores" = "Seleccione uno o más años",
                         "Tiempo" = "Seleccione uno o más años, para comparar",
                         "Seleccione uno o más años" # acá es donde caen las pestañas por default si no se indica antes nada
    )
    
    updateSelectInput(session, "filtro_anio",
                      label = tagList("Año ", tags$br(), tags$small(class = "text-muted", texto_anio))
    )
    
    # Departamento 
    output$ayuda_depto <- renderUI({
      if (input$navbar == "Indicadores") {
        return(NULL)  
        }
      
      texto_depto <- switch(input$navbar,
                            "Lugar" = "Seleccione uno para ver localidades, o todos para la provincia",
                            "Seleccione uno, varios o todos"
      )
      tags$label(class = "control-label",
                 tagList("Departamento ", tags$br(), tags$small(class = "text-muted", texto_depto)))
    })
    
  })
  
  
  # módulos --------------------------------------------------------
  
  df_tabla_indicadores <- moduloIndicadoresServer("indicadores", base_sin_filtro_depto, anios_seleccionados, evento_seleccionado)
  moduloPersonaServer("persona", base_filtrada)
  moduloLugarServer("lugar", base_filtrada, depto_seleccionado,anios_seleccionados)
  moduloTiempoServer("tiempo",base_filtrada,anios_seleccionados,base_sin_anio)
  
  
  # descargas -------------------------------------------------------------

  output$descargar_tabla <- downloadHandler(
    filename = function() {
      paste0("indicadores_tablero_", Sys.Date(), ".xlsx")
    },
    content = function(file) {
      openxlsx::write.xlsx(df_tabla_indicadores(), file)
    }
  )
  
}
