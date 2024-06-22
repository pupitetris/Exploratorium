TODO
====

- Actualizaciones:
  - [ ] Ecmascript (módulos)
  - [x] Bootstrap 5
  - [ ] MathJax 3.2
  - [x] D3 v7
  - [ ] Checar en Safari

- Infraestructura:
  - [ ] Documentación!
  - [ ] npm
  - [x] generador en maquina de Mariana
  - [x] GitHub
    - [ ] GitHub para Mariana
  - [x] Google Analytics
  - [x] Templates: Traducciones para aria-label et al.

- Bugs:
  - [x] Algunos getAttrId(attr) devuelven cadena vacía.
        Ejemplo: click en spacetimes/Newton-Cartan S-T/(dt ⊗ K)=0 (pero en classical sí funciona)
    - [x] Todavía: theories-es/basic: Colission between {B} and {B*}. attr_id: b

  - [x] La redacción en español del texto introductorio del Inicio no
        está al corriente con la versión en inglés (Neil Dewar).
  - [x] Cuando arrastro un nodo fuera del viewport, ya no puedo seleccionarlo de nuevo
  - [x] Feedback de que las etiquetas son interactuables. manita o algo al pasar sobre las etiquetas.
  - [x] Info no visible porque está hasta abajo del diagrama. que la info salga más cerca de la etiqueta.
  - [ ] Algunas ecuaciones de MathJax no jalan
  - [x] Algunos colores de textbox no jalaron su colorcito y están en negro.
  - [x] Atributos amarillos en transparencia no se ven
  - [x] Etiquetas de atributos que se enciman.
  - [x] Pegar el footer al inferior de la pantalla si la página es más
        corta que la ventana.
  - [x] Diagrama y título e intro no están centrados.
  - [ ] En zoom negativo, no jala el pan.
  - [x] El tool de infobox se encima sobre el infobox (z-index)
  - [ ] Dump de SQL debe de registar el estado de las secuencias.
  - [x] Fullscreen: handlear usuario saliendo de fullscreen sin usar el toolbar.
  - [ ] En algunos diagramas, los node levels se traslapan con el node dot.
  - [ ] Homologar config.json? Yes
  - [x] Traducibles las descripciones de nodos en la leyenda
  - [x] Editor invalida caché, y que sea con ?editor en vez de #editor

- Mejoras:
  - [x] Menú de teorías en el navbar
  - [x] Recuperar el verde abajo del pasto.
  - [x] Botón opcional para volver casi transparente las ligas al ínfimo. 
  - [x] Zoom in/out y paneo
  - [x] Atributos en abanico. <- tal vez mejor dos columnas.

  - [x] Click en infimo .active le quita el .active
  - [x] Tooltips en toolbars
  - [x] Infobox: párrafo (columna de desc.csv) especial de ecuación.
  - [x] Remover el texto del autor en la páginas de los diagramas.
  - [ ] Todos los svgs se van a 16:9
  - [ ] Repasar el feature de subrayado (double click en nodos).
  - [ ] Infobox: poner attribute class dentro del texto.
  - [ ] Resaltar nodo seleccionado.
  - [x] Que el nav flote arriba al scrollear hacia abajo la página.
  - [ ] Editor: snaps: colineal, horizontal y vertical.
  - [ ] Editor: tool de "organize by level"
  - [ ] Tool: switch a otro diagrama desde el fullscreen.
  - [ ] config.js -> config.json
  - [ ] Usar IDs numéricos para lang, requisito para Budibase.
  - [ ] Support for more than two languages.
  - [ ] Attributes have no code??

- Nice to have
  - [ ] Acceso a los datos tabulares de los contextos.
  - [ ] Nodos "interesantes" con highlight, y hint explicativo.
  - [ ] Infobox: ligar gráficamente al elemento clickeado.
  - [ ] Editor: poder alterar todos los parametros de config.json
  - [ ] Editor: persist diagram changes using local storage.
