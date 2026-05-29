# tablero-santa-fe
Tablero de información de eventos de notificación obligatoria de la provincia de Santa Fe

## Propósito

Facilitar la vigilancia y seguimiento de la situación epidemiológica y dinámica de los eventos de notificación obligatoria (ENOS), para contribuir con la toma de decisiones basadas en datos precisos y actualizados.

## Objetivo

Acercar información epidemiológica clara y comprensible a áreas de responsabilidad, para fortalecer la vigilancia activa y las acciones ante eventuales brotes o el aumento de casos de ENOS.

## Usuarios

Responsables de la vigilancia y acciones ante eventuales brotes o aumento de casos.

---

# Arquitectura 

## Organización propuesta

```text
app/
├── global.R
├── ui.R
├── server.R
│
├── modulos/
│   ├── modulo_persona/
│   │   ├── mod_persona_ui.R
│   │   └── mod_persona_server.R
│   │
│   ├── modulo_lugar/
│   │   ├── mod_lugar_ui.R
│   │   └── mod_lugar_server.R
│   │
│   └── modulo_tiempo/
│       ├── mod_tiempo_ui.R
│       └── mod_tiempo_server.R
│
├── helpers/
│   ├── helpers_persona.R
│   ├── helpers_lugar.R
│   └── helpers_tiempo.R
│
├── data/
│   ├── base_eventos.csv
│   ├── estimaciones_poblacionales.csv
│   └── mapas/
│
└── www/
    ├── estilos.css
    └── logo.png

```

## Componentes principales

•	Global: lectura de archivos y source de los helpers.
•	UI: navbar, sidebar, y placeholders de las UIs de los módulos.
•	Server: filtro a la base principal en base a inputs de usuario y llamada a los módulos.
•	Módulos: (ui + server) lógica reactiva y outputs de cada sección. Reciben la base filtrada como argumento.
•	Helpers: contienen las funciones necesarias y específicas para cada módulo (por ejemplo, calcular_indice_x(), dibujar_mapa(), etc.) 

---

## Flujo general

```text

global.R
   ↓
Carga de datos y helpers
   ↓
server()
   ↓
Filtros globales (evento, año, departamento)
   ↓
base_filtrada()
   ↓
Módulos
   ├── Persona
   ├── Lugar
   └── Tiempo
```

### Módulo Persona

*	El módulo recibe como argumento el reactive base_filtrada
*	La UI del módulo contiene los inputs 
o	tipo_grafico (para elegir entre pirámide para sexo y edad o histograma solo para edad)
o	mostrar_datos (para elegir entre nro de casos y porcentaje)
-	En el server del módulo, según tipo_grafico, se llama a la función helper grafico_sexo_edad() o grafico_edad(), que reciben como argumentos a la base_filtrada() y el input de tipo de datos, con lo cual generarán la visualización correspondiente. Ese es el output principal.
-	Además, se generan los outputs para los valueboxes (mediana de edad, razón hombre mujer, rango etario más afectado).

### Módulo Lugar

-	El módulo recibe como argumentos el reactive base_filtrada, y el reactive depto_seleccionado definido en el server principal a partir de la información del input filtro_depto (para que pueda llegar la info al módulo)
-	La UI del módulo contiene el input mostrar datos (para elegir entre nro de casos y tasas), en caso de que estén seleccionados todos los departamentos. 
-	En el server del módulo, según tipo_gráfico, se llamará a la función helper dibujar_mapa(), que recibirá como argumentos a la base_filtrada y el depto_seleccionado. Según depto_seleccionado se graficará un mapa de toda la provincia, con los valores para todos los departamentos (mapa de polígonos), o el departamento seleccionado con sus localidades (mapa de círculos). Ese será el output principal.
-	Además, se generarán los outputs para los valueboxes 

### Módulo Tiempo

-	El módulo recibe como argumento el reactive base_filtrada.
-	La UI del módulo contiene los inputs mostrar_datos (para elegir entre nro de casos y tasas), y tipo_gráfico (para elegir entre distribución por SE, por mes, por año, o corredor endémico).
-	En el server del módulo, según tipo_gráfico, se llamará a la función helper correspondiente. Según mostrar_datos se generará el gráfico correspondiente. Ese será el output principal.
-	Además, se generarán los outputs para los valueboxes 

## Diseño UI

Se usará la librería bslib para generar un layout con navbar superior, donde se ubicarán las pestañas correspondientes a cada módulo, un sidebar donde estarán los inputs glogales, y un panel centrar donde se mostrarán los outputs y filtros específicos de cada módulo.

## Decisiones de diseño 

- Se usa una arquitectura modular para facilitar escalabilidad y mantenimiento
- La interfaz se construirá con `bslib` para mantener consistencia visual y responsividad.
- Los filtros globales se centralizan en el server principal
- Los módulos reciben reactives y no dataframes estáticos.. 
- Los helpers se diseñan como funciones independientes de Shiny para facilitar reutilización y mantenimiento.
