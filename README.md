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
│   ├── modulo_indicadores/
│   ├── modulo_persona/
│   ├── modulo_lugar/
│   └── modulo_tiempo/
│
├── helpers/
│   ├── helpers_indicadores.R
│   ├── helpers_persona.R
│   ├── helpers_lugar.R
│   └── helpers_tiempo.R
│
├── archivos/
│   ├── base_eventos.xlsx
│   ├── poblacion_deptos.xlsx
│   ├── shp_deptos/
│   └── shp_localidades/
│
└── www/
    ├── estilos.css
    └── logo-santa-fe.png

```

## Componentes principales

- Global: lectura de archivos y source de los helpers y módulos.
- UI: navbar, sidebar, y placeholders de las UIs de los módulos.
- Server: filtro a la base principal en base a inputs de usuario y llamada a los módulos.
- Módulos: (ui + server) lógica reactiva y outputs de cada sección. Reciben la base filtrada como argumento.
- Helpers: contienen las funciones necesarias y específicas para cada módulo (por ejemplo, calcular_indice_x(), dibujar_mapa(), etc.) 

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
   ├── Indicadores
   ├── Persona
   ├── Lugar
   └── Tiempo
```

### Módulo Indicadores
- El módulo recibe como argumento el reactive de la base filtrada por año y evento (`base_sin_filtro_depto`), el reactive con los años seleccionados a partir del input global (`anios_seleccionados()`) y el reactive con el evento seleccionado (`eevnto_seleccionado()`).
- Para este módulo se oculta el filtro global de departamentos, ya que la idea es mostrar la información de todos juntos.
- En el server del módulo se llama a las funciones `calcular_tabla_indicadores()` y `mapa_deptos_indicadores()`, que generan la tabla y el gráfico respectivamente, los cuales se renderizan con `renderReactable` y `renderLeaflet`.
- Además, se generan los outputs para los value boxes (Total de casos, Confirmados, Fallecidos).
- También se genera un botón de descarga de la tabla (a partir del df devuelto por el módulo, en el server global).

### Módulo Persona
- El módulo recibe como argumento el reactive de la base filtrada por año, departamento y evento (`base_filtrada()`).
- La UI del módulo contiene los inputs:
  - Tipo de gráfico (`tipo_grafico`), para elegir entre pirámide para sexo y edad o histograma solo para edad.
  - Mostrar como (`mostrar_como`), para elegir entre nro de casos y porcentaje.
  - Tipo de casos (`clasif_casos`), para elegir entre total notificados, confirmados y probables.
- En el server del módulo, se prepara el df según `clasif_casos` se haya seleccionado. Según `tipo_grafico`, se llama a la función helper `grafico_sexo_edad()` o `grafico_edad()`, que reciben como argumentos a `base_filtrada()` y el input de `mostrar_como`, con lo cual se genera la visualización correspondiente. Ese es el output principal.
- Además, se generan los outputs para los value boxes (mediana de edad, razón hombre mujer, rango etario más afectado).

### Módulo Lugar
- El módulo recibe como argumentos el reactive `base_filtrada()`, y el reactive del departamento seleccionado (`depto_seleccionado()`) definido en el server principal a partir de la información del input `filtro_depto` (para que pueda llegar la info del input al módulo). También el reactive `anios_seleccionados()`.
- La UI del módulo contiene los inputs:
  - Mostrar como (`mostrar_como`), para elegir entre nro de casos y tasas. Solo se muestra en caso de que estén seleccionados todos los departamentos en el filtro global; cuando hay seleccionado uno solo se oculta con conditional panel (usando el output `vista_provincial`).
  - Tipo de casos (`clasif_casos`), para elegir entre total notificados, confirmados y probables.
- En el server del módulo, según `depto_seleccionado()`, se llama a la función helper `mapa_provincia()` o `mapa_departamento()`. Ambas toman como argumentos a `mostrar_como` y `clasif_casos`. Se grafica entonces, o bien un mapa de toda la provincia, con los valores para todos los departamentos (mapa de polígonos), o bien el departamento seleccionado con sus localidades (mapa de círculos). Ese es el output principal.
- Además, se generan los outputs para los value boxes.

### Módulo Tiempo

-	El módulo recibe como argumentos el reactive `base_filtrada()`, `anios_seleccionados()` y una base filtrada solo por evento y departamento, sin filtrar por año (`base_sin_anio()`), necesaria para el gráfico agrupado por año.
-  La UI del módulo contiene los inputs:
   -	Tipo de gráfico (`tipo_grafico`): para elegir entre distribución por semana epidemiológica o por año.
   -	Mostrar (`vista_semana`): visible solo cuando la agrupación es "semana" y hay un único año seleccionado (mediante conditionalPanel). Permite elegir entre comparar varios años con líneas, o ver un solo año con barras.
   -	Tipo de casos (`tipo_casos`): para elegir entre total notificado, confirmados o probables.
-  En el server del módulo, un reactive interno (`base_activa()`) decide qué base usar: `base_sin_anio()` si la agrupación es "año" (para no perder años por el filtro global), o `base_filtrada()` en cualquier otro caso. Según `tipo_grafico` y `vista_semana`, la función helper `grafico_temporal()` genera el gráfico correspondiente:
   -	tipo de grafico "año": barras con todos los años disponibles.
   -	tipo de grafico "semana" + vista "barras": barras de un único año, completando con 0 las semanas sin casos.
   -	tipo de grafico "semana" + vista "líneas": una línea por cada año seleccionado, para comparar la distribución estacional entre años.
-  En todos los casos, tipo_casos determina si se grafica el total notificado, los confirmados o los probables. Ese gráfico es el output principal.
-  Además, se generan los outputs para los value boxes (total de casos, tasa de incidencia acumulada, período con mayor carga), calculados con `calcular_resumen_tiempo()`.

## Diseño UI

Se usa la librería bslib para generar un layout con navbar superior, donde se ubican las pestañas correspondientes a cada módulo, un sidebar donde están los inputs glogales, y un panel central donde se muestran los outputs y filtros específicos de cada módulo.

## Decisiones de diseño 

- Se usa una arquitectura modular para facilitar escalabilidad y mantenimiento
- Los filtros globales se centralizan en el server principal
- Los módulos reciben reactives y no dataframes estáticos.. 
- Los helpers se diseñan como funciones independientes de Shiny para facilitar reutilización y mantenimiento.
