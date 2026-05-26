Rails.application.config.active_storage.variant_processor = :vips

# ⚠️  RIESGO DE SEGURIDAD ACEPTADO: XSS vía SVG inline.
#
# Por defecto ActiveStorage fuerza que `image/svg+xml` se sirva como binario
# (Content-Type: application/octet-stream, Content-Disposition: attachment)
# precisamente porque un SVG es un documento XML que puede contener:
#   - <script>...</script>
#   - handlers de eventos en línea (onclick, onload, onmouseover, ...)
#   - <foreignObject> con HTML/JS embebido
#   - <use href="..."> apuntando a recursos externos
#
# Al permitirlo inline, cuando un usuario visita la URL del blob el navegador
# ejecuta ese contenido en el ORIGEN de la aplicación. Eso significa que un
# miembro malicioso del proyecto podría:
#   - Leer/exfiltrar la sesión de Devise de otros miembros que abran el SVG.
#   - Hacer requests autenticados contra la API en nombre de la víctima.
#   - Pivotar a robo de cuentas si la víctima es owner del proyecto.
#
# Por qué se acepta hoy:
#   - Sólo usuarios autenticados (Devise) y miembros del proyecto pueden subir
#     documentos, así que el atacante ya está dentro del trust boundary.
#   - El producto es colaborativo entre equipos relativamente pequeños donde
#     se asume confianza entre miembros del mismo proyecto.
#   - La alternativa (descargar siempre) rompe el caso de uso de previsualizar
#     SVGs en la sección de Documentos.
#
# Mitigaciones pendientes (hacer antes de abrir el producto a usuarios no
# confiables o de añadir compartición pública de documentos):
#   1. Sanitizar el SVG al subirlo (gem `loofah` o `sanitize`) removiendo
#      <script>, atributos `on*` y referencias externas, y guardar la versión
#      saneada. Renderizar inline como <svg> en vez de via <img>/url_for.
#   2. O servir los blobs desde un subdominio distinto sin cookies (origen
#      separado para aislar la sesión).
#   3. Añadir una CSP estricta que bloquee scripts inline.
ActiveStorage.content_types_to_serve_as_binary -= [ "image/svg+xml" ]
ActiveStorage.content_types_allowed_inline |= [ "image/svg+xml" ]
