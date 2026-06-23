
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
  
 
  # observers ------------------------------------------------------------------
  
  # para ocultar input de departamento en pestaña indicadores
  observe({
    if (input$navbar == "Indicadores") {
      shinyjs::hide("filtro_depto")
    } else {
      shinyjs::show("filtro_depto")
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
  

  # módulos --------------------------------------------------------

  moduloIndicadoresServer("indicadores", base_sin_filtro_depto,anios_seleccionados)
  moduloPersonaServer("persona", base_filtrada)
  moduloLugarServer("lugar", base_filtrada, depto_seleccionado,anios_seleccionados)
  moduloTiempoServer("tiempo",base_filtrada,anios_seleccionados,base_sin_anio)

  
  # descargas -------------------------------------------------------------
  
  df_tabla_indicadores <- moduloIndicadoresServer("indicadores", base_sin_filtro_depto, anios_seleccionados)
  
  output$descargar_tabla <- downloadHandler(
    filename = function() {
      paste0("indicadores_tablero_", Sys.Date(), ".xlsx")
    },
    content = function(file) {
      openxlsx::write.xlsx(df_tabla_indicadores(), file)
    }
  )
  
}
