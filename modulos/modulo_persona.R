# ui ---------------------------------------------------------------------------

moduloPersonaUI <- function(id) {
  ns <- NS(id)
  tagList(
    
    # fila value boxes ---------------------------------------------------------------
    div(
      class = "value-boxes",
      layout_columns(
        fill = FALSE,
        height = "100px",          
        value_box(
          title = "Mediana de edad",
          value = textOutput(ns("vb_mediana_edad")),
          showcase = icon("calendar")
        ),
        value_box(
          title = "Razón H/M",
          value = textOutput(ns("vb_razon_hm")),
          showcase = icon("venus-mars")
        ),
        value_box(
          title = "Rango etario más afectado",
          value = textOutput(ns("vb_rango_etario")),
          showcase = icon("chart-bar")
        )
      )
    ),
    
    # fila con inputs a la derecha, gráfico a la izquierda ------------------------------
    layout_columns(
      col_widths = c(9,3),     
      card(
        min_height = "500px", 
        card_header("Distribución por persona"),
        highchartOutput(ns("grafico_principal"))
      ),
      card(
        card_header("Opciones gráfco"),
        radioButtons(ns("tipo_grafico"), "Tipo de gráfico",
                     choices = c("Sexo y edad (pirámide)" = "sexo_edad", "Edad (barras)" = "edad"),
                     selected = "sexo_edad"),
        radioButtons(ns("mostrar_como"), "Mostrar como",
                     choices = c("Porcentaje" = "porcentaje","Número de casos" = "casos"),
                     selected = "porcentaje"),
        radioButtons(ns("clasif_casos"), "Tipo de casos",
                     choices = c("Total notificado" = "total","Confirmados" = "confirmados","Probables"="probables"),
                     selected = "total")
      )
    )
  )
}

# server -----------------------------------------------------------------------

moduloPersonaServer <- function(id, base_filtrada) {
  moduleServer(id, function(input, output, session) {
    
    # value boxes --------------------------------------------------------------
    
    output$vb_mediana_edad <- renderText({
      calcular_mediana_edad(base_filtrada())   
    })
    
    output$vb_razon_hm <- renderText({
      calcular_razon_hm(base_filtrada())
    })
    
    output$vb_rango_etario <- renderText({
      calcular_rango_etario(base_filtrada())
    })
    
    # gráfico principal ---------------------------------------------------------
    
    output$grafico_principal <- renderHighchart({
  
      df_grafico <- switch(input$clasif_casos, # según clasif_casos sea "total", "confirmados" o "probables, se ejectuta solo la sentencia correspondiente. Se filtra la base para pasar a la función para hacer el gráfico 
                           total = base_filtrada(),
                           confirmados = base_filtrada() |> filter(CLASIFICACION == "CONFIRMADO"),
                           probables= base_filtrada() |> filter(CLASIFICACION == "PROBABLE")
      )
      
      if (input$tipo_grafico == "sexo_edad") {
        grafico_sexo_edad(df_grafico, input$mostrar_como)
      } else {
        grafico_edad(df_grafico, input$mostrar_como)
      }
    })
  })
}
