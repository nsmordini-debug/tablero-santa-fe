
ui <- page_navbar(
  
  # title = tagList(
  #   img(src = "LogoColor.png", height = "30px", style = "margin-right: 8px;"),
  #   "Tablero Epidemiológico"
  # ),
  
  title = tagList(
    img(src = "LogoColor.png", height = "40px", style = "margin-right: 12px;"),
    tags$span("Tablero Epidemiológico", 
              style = "font-weight: 400; opacity: 0.85;")
  ),
  
  id = "navbar",
  
  header = tagList(
    useShinyjs(),                            
    # tags$head(
    #   tags$link(rel = "stylesheet", type = "text/css", href = "estilos.css")
    # )
  ),
  
  theme = bs_theme(bootswatch = "zephyr") |> #flatly, minty, yeti
    bs_add_rules("
      .value-boxes .value-box-value {
        font-size: 1.7rem !important;
      }
      .value-boxes .value-box-showcase {
        font-size: 1.1rem !important;
      }
      .value-boxes {
        margin-bottom: -20px; /*p disminuir espacio dp de los vb*/
      }
      "),
  
  # sidebar global (filtros compartidos entre todas las pestañas) --------------
  
  sidebar = sidebar(
    width = 260,
    title = "Filtros",
    
    selectInput(
      inputId = "filtro_evento",
      label= "Evento",
      choices = eventos_disponibles,
      selected = "Coqueluche"
    ),
    
    selectInput(
      inputId = "filtro_anio",
      label = "Año",
      choices = anios_disponibles,
      selected = 2025, #anios_disponibles,   
      multiple = TRUE
    ),
    
    pickerInput(
      inputId = "filtro_depto",
      label = "Departamento",
      choices = deptos_disponibles,
      selected = deptos_disponibles,  
      multiple = TRUE,
      options = list(
        `actions-box` = TRUE,
        `select-all-text` = "Seleccionar todos",
        `deselect-all-text` = "Deseleccionar todos",
        `none-selected-text`= "— Sin filtro (todos) —",
        `selected-text-format` = "count > 2",  
        `count-selected-text` = "{0} seleccionados",
        container = "body"
      )
    ),
    conditionalPanel(
      condition = "input.navbar == 'Indicadores'",
      downloadButton("descargar_tabla", "Descargar tabla (.xlsx)", class = "btn-sm")
    )
  ),
  
  # pestañas (una para cada módulo) --------------------------------------------
  
  nav_panel(
    title = "Indicadores",
    icon = icon("table"), #fontawesome.com/icons
    moduloIndicadoresUI("indicadores")
  ),
  
  nav_panel(
    title = "Persona",
    icon = icon("person"),
    moduloPersonaUI("persona")
  ),
  
  nav_panel(
    title = "Lugar",
    icon = icon("map"),
    moduloLugarUI("lugar")
  ),
  
  nav_panel(
    title = "Tiempo",
    icon = icon("clock"),
    moduloTiempoUI("tiempo")
  ),
  
  nav_panel(
    title = "Acerca de",
    icon = icon("circle-info"),
    card(
      card_header("Acerca de este tablero"),
      includeMarkdown("README.md")
    )
  )
)
