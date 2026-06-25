
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
    
# Estructura de pestañas para separar Distribución y Corredor --------------
    navset_card_tab(
      nav_panel(
        title = "Distribución Temporal",
        layout_columns(
          col_widths = c(9, 3),
          card(
            card_header("Distribución temporal"),
            highchartOutput(ns("grafico_tiempo"), height = "450px")
          ),
          card(
            card_header("Opciones gráfico"),
            radioButtons(
              inputId = ns("agrupacion"),
              label = "Tipo de gráfico",
              choices = c("Semana epidemiológica" = "semana", "Año" = "anio"),
              selected = "semana"
            ),
            conditionalPanel(
              condition = "input.agrupacion == 'semana' && output.un_solo_anio",
              ns = ns,
              radioButtons(
                inputId = ns("vista_semana"),
                label = "Mostrar",
                choices = c("Comparar años (líneas)" = "lineas", "Un año (barras)" = "barras"),
                selected = "lineas"
              )
            ),
            radioButtons(
              inputId = ns("tipo_casos"),
              label = "Tipo de casos",
              choices = c("Total notificado" = "casos", "Confirmados" = "confirmados", "Probables" = "probables"),
              selected = "casos"
            )
          )
        )
      ),
      
<<<<<<< HEAD
      nav_panel(
        title = "Corredor Endémico",
        layout_columns(
          col_widths = c(9, 3),
          card(
            card_header("Canal Endémico"),
            plotlyOutput(ns("grafico_corredor"), height = "450px")
          ),
          card(
            card_header("Opciones Corredor"),
            p("El corredor calcula los cuartiles históricos excluyendo el año seleccionado como actual."),
            uiOutput(ns("selector_anio_actual"))
          )
=======
      card(
        card_header("Distribución temporal"),
        highchartOutput(ns("grafico_tiempo"), height = "450px")
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
          radioButtons(
            inputId = ns("vista_semana"),
            label = "Mostrar",
            choices = c("Comparar años (líneas)" = "lineas", "Un año (barras)"= "barras"),
            selected = "lineas"
          )
        ),
        # radioButtons(
        #   inputId  = ns("metrica"),
        #   label    = "Mostrar como",
        #   choices  = c("Número de casos" = "casos", "Tasa x 100.000 hab." = "tasa"),
        #   selected = "casos"
        # )
        radioButtons(
          inputId = ns("clasif_casos"),
          label = "Tipo de casos",
          choices = c("Total notificado" = "casos", "Confirmados" = "confirmados", "Probables" = "probables"),
          selected = "casos"
>>>>>>> d217e2f6ee23d6b3dacf02877707f0b812504fc3
        )
      )
    )
  )
}

# server -----------------------------------------------------------------------
moduloTiempoServer <- function(id, base_filtrada, anios_seleccionados, base_sin_anio) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
<<<<<<< HEAD
    # Base según se elija por año o semana
=======
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
>>>>>>> d217e2f6ee23d6b3dacf02877707f0b812504fc3
    base_activa <- reactive({
      if (input$tipo_grafico == "anio") base_sin_anio() else base_filtrada()
    })
    
    # Value boxes cálculo único unificado 
    resumen <- reactive({
<<<<<<< HEAD
      calcular_resumen_tiempo(
        base_activa(), 
        input$agrupacion, 
        poblacion, 
        anios_seleccionados()
      )
=======
      calcular_resumen_tiempo(base_activa(), input$tipo_grafico, poblacion, anios_seleccionados())
>>>>>>> d217e2f6ee23d6b3dacf02877707f0b812504fc3
    })
    
    output$vb_total <- renderText({ resumen()$total })
    output$vb_tasa <- renderText({ resumen()$tasa })
    output$vb_periodo_max <- renderText({ resumen()$periodo_max })
    
    # Condición para mostrar opciones de semanas en la UI
    output$un_solo_anio <- reactive({
      length(anios_seleccionados()) == 1
    })
    outputOptions(output, "un_solo_anio", suspendWhenHidden = FALSE)
    
    # Gráfico de distribución temporal (Highcharts)
    output$grafico_tiempo <- renderHighchart({
      grafico_temporal(
        base_activa(),
        input$tipo_grafico,
        input$clasif_casos,
        poblacion,
        anios_seleccionados(),
        input$vista_semana   
      )
    })
    
    
    
# Sección Corredor Endémico -----------------------------------------------
    
    biblioteca (tidyverse)
    Biblioteca (trama)
    
    set.seed(123)
    
# Genera datos
    
    anios <- 2022:2026
    semanas <- 1:52
    
    datos <- expand_grid(
      anio = anio,
      semana_epidemiologica = semana
    ) %>%
      mutar (
        estacionalidad = 25 + 40 * exp(-((semana_epidemiologica - 14)^2) / 80),
        ruido = rpois(n(), lambda = 8),
        casos = round(estacionalidad + ruido),
        casos = if_else(anio %in% c(2022, 2025) &
                          semana_epidemiologica %in% 8:24,
                        round(casos * runif(n(), 2.0, 3.2)),
                        casos),
        casos = if_else(anio == 2026 &
                          semana_epidemiologica %in% 10:22,
                        round(casos * runif(n(), 1.4, 2.1)),
                        casos)
      ) %>%
      select(anio, semana_epidemiologica, casos)
    
    
    # Separa años históricos y año actual
    
    anio_actual < - 2026
    
    Historico <- Datos %>%
      filtro (anio < anio_actual)
    
    Actual <- datos %>%
      filter(anio == anio_actual)
    
    
    # calcula corredor endémico
    
    corredor <- histórico %>%
      group_by(semana_epidemiologica) %>%
      resumse(
        q25 = cuantil(casos, 0,25, na.rm = VERDADERO),
        q50 = cuantil (casos, 0,50, na.rm = TRUE),
        q75 = cuantil(casos, 0,75, na.rm = TRUE),
        maximo = max(casos, na.rm = TRUE),
        .grupos = "caída"
      ) %>%
      left_join(actual, by = "semana_epidemiologica")
    
    
    # clasifica por zonas
    
    
    corredor <- corredor %>%
      mutar (
        zona = case_when(
          casos < q25 ~ "Éxito",
          casos >= q25 & casos < q50 ~ "Seguridad",
          casos >= q50 & casos < q75 ~ "Alerta",
          casos >= q75 ~ "Epidemia",
          CIERTO ~ NA_character_
        )
      )
    
# gráfica el corredor endémico
    
    corredorEndemico = ggplot(corredor, aes(x = semana_epidemiologica)) +
      geom_ribbon(aes(ymin = 0, ymax = q25),
                  llenado = "#b7e4c7", alfa = 0,8) +
      geom_ribbon(aes(ymin = q25, ymax = q50),
                  llenado = "#fff3b0", alfa = 0,8) +
      geom_ribbon(aes(ymin = q50, ymax = q75),
                  llenado = "#fcbf49", alfa = 0,8) +
      geom_ribbon(aes(ymin = q75, ymax = máximo),
                  llenado = "#e63946", alfa = 0,7) +
      geom_line(aes(y = casos),
                Ancho de línea = 1,2, color = "negro") +
      geom_point(aes(y = casos),
                 Tamaño = 2, color = "negro") +
      laboratorios(
        title = "Corredor endémico - Datos simulados",
        subtitle = paste("Año actual:", anio_actual),
        x = "Semana epidemiológica",
        y = "Casos",
        pie de foto = "Datos falsos generados dentro del propio script"
      ) +
      scale_x_continuous(pausas = seq(1, 52, by = 4)) +
      theme_minimal()
    
    ggplotly(corredorEndemico)
    
    
    # renderiza ggplotly en shinyapp
    
    Biblioteca (brillante)
    
    UI <- fluidPage(
      plotlyOutput("corredor")
    )
    
    Server <- Function(Input, Output, Session) {
      output$corredor = renderPlotly({
        corredorEndemico
      })
    }
    
    shinyApp(ui, servidor)
    
    
    
    
    
    
    
    
    
    
    
    
    
