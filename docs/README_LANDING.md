# Tivo Landing Page

Landing page moderna y profesional para Tivo - aplicación de gestión de proyectos y planificación colaborativa.

## Características

### Diseño y Tecnología
- **HTML + ERB**: Semántico y accesible
- **Tailwind CSS**: Utilidades only, sin clases personalizadas
- **Responsive**: Mobile-first approach
- **SEO Optimizado**: Meta tags para redes sociales
- **Smooth Scrolling**: Navegación fluida entre secciones

### Estructura de la Landing Page

1. **Navegación Fija**
   - Logo Tivo con gradiente de color
   - Links de navegación anclados a secciones
   - Botones de CTA (Iniciar Sesión / Comenzar Gratis)
   - Menú hamburguesa para móvil

2. **Hero Section**
   - Headline impactante con gradiente
   - Subheadline explicando el valor
   - CTA principal y secundario
   - Mockup placeholder de la aplicación

3. **Features Section**
   - Grid de 6 características principales
   - Iconos relevantes para cada feature
   - Hover effects con transiciones suaves
   - Colores diferenciados por categoría

4. **How It Works**
   - 4 pasos simples con números circulares
   - Flujo claro de onboarding
   - Diseño centrado y limpio

5. **Use Cases**
   - 4 casos de uso específicos
   - Cards con gradientes de fondo
   - Iconos temáticos por industria

6. **Benefits Section**
   - Estadísticas cuantificables
   - Tipografía grande y bold
   - Beneficios clave con colores

7. **CTA Final**
   - Gradiente de fondo fuerte
   - Llamado a la acción potente
   - Mensaje de confianza

8. **Footer**
   - Links organizados por categorías
   - Diseño oscuro profesional
   - Copyright y información legal

## Paleta de Colores

- **Primary**: Azul moderno (#3B82F6)
- **Secondary**: Púrpura (#8B5CF6)
- **Accent**: Verde para success (#10B981)
- **Neutral**: Grises para texto y backgrounds
- **Background**: Blanco con gradientes sutiles

## Implementación Técnica

### Layouts
- `public.html.erb`: Layout específico para la landing page
- `application.html.erb`: Layout principal para usuarios autenticados

### Controller
- `HomeController`: Maneja la vista de la landing page
- Usa layout "public" para separar del resto de la aplicación

### Rutas
- `root to: "home#index"`: La landing page es la página principal

### SEO y Meta Tags
- Descripción optimizada para motores de búsqueda
- Open Graph tags para Facebook
- Twitter Card tags para redes sociales
- Keywords relevantes

### JavaScript
- Smooth scrolling para navegación
- Menú móvil funcional
- Cierre automático del menú al hacer click

## Personalización

### Textos y Contenido
Editar directamente en `app/views/home/index.html.erb`:
- Headlines y descripciones
- Características y beneficios
- Casos de uso

### Colores y Estilos
Modificar clases de Tailwind CSS:
- Cambiar gradientes en `bg-gradient-to-*`
- Ajustar colores en `text-*` y `bg-*`
- Personalizar hover effects

### Links de Navegación
Actualizar en la sección `<nav>`:
- Agregar/quitar secciones
- Modificar textos de los links
- Ajustar CTA buttons

## Deploy y Producción

La landing page está lista para producción:
- Optimizada para rendimiento
- Responsive en todos los dispositivos
- Compatible con Rails + Tailwind CSS
- SEO-friendly

## Consideraciones

- No se usa JavaScript inline (sigue convenciones del proyecto)
- Solo utiliza utilidades de Tailwind CSS
- El layout está separado del resto de la aplicación
- Los links de navegación usan anclajes smooth
- Las rutas de autenticación están integradas

---

**Creado**: Noviembre 2024
**Framework**: Rails + ERB + Tailwind CSS
**Diseño**: Moderno, profesional, conversion-focused
