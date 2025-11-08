# Guía para Agentes de IA - Expressativo

## Reglas Generales de Desarrollo

### 🚫 JavaScript Inline - PROHIBIDO
**NUNCA** uses JavaScript inline en las vistas. **SIEMPRE** crea un Stimulus controller.

❌ **Incorrecto:**
```erb
<button onclick="doSomething()">Click</button>
<script>
  function doSomething() {
    // código...
  }
</script>
```

✅ **Correcto:**
```erb
<!-- Vista -->
<div data-controller="feature">
  <button data-action="click->feature#doSomething">Click</button>
</div>
```

```javascript
// app/javascript/controllers/feature_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  doSomething() {
    // código...
  }
}
```

### 📁 Estructura de Stimulus Controllers

Los controllers deben estar en: `app/javascript/controllers/`

**Convenciones:**
- Nombres en snake_case: `dropdown_controller.js`, `clipboard_controller.js`
- Siempre importar desde `@hotwired/stimulus`
- Usar targets, values y actions apropiadamente
- Agregar comentarios descriptivos

**Ejemplo de estructura:**
```javascript
import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="nombre"
export default class extends Controller {
  static targets = ["elemento"];
  static values = {
    opcion: { type: String, default: "valor" }
  };

  connect() {
    // Se ejecuta cuando el controller se conecta al DOM
  }

  disconnect() {
    // Limpiar event listeners, timers, etc.
  }

  // Tus métodos aquí
}
```

### 🎨 Estilos y UI

- **Framework CSS:** Tailwind CSS
- **Componentes:** Flowbite (pero implementados con Stimulus, no con su JS)
- **Iconos:** Tabler Icons (SVG inline)
- **Clases de utilidad:** Definidas en `app/assets/stylesheets/application.css`

**Clases personalizadas disponibles:**
- `.button` - Botón primario
- `.button-outline` - Botón con borde
- `.input` - Input de formulario
- `.label` - Label de formulario

### 🛣️ Rutas de Rails

**Convenciones:**
- Usar recursos RESTful cuando sea posible
- Para acciones custom en recursos, usar `member` o `collection`
- Mantener las rutas organizadas y comentadas

**Ejemplo:**
```ruby
resources :projects do
  resources :members, controller: "project_members"
  
  member do
    post :custom_action
  end
end
```

### 🗄️ Modelos y Base de Datos

**Antes de crear migraciones:**
1. Verificar que el campo/tabla no exista
2. Usar nombres descriptivos en snake_case
3. Agregar índices cuando sea necesario
4. Considerar validaciones y asociaciones

**Ejemplo de migración:**
```ruby
class AddFieldToModel < ActiveRecord::Migration[8.0]
  def change
    add_column :models, :field_name, :string
    add_index :models, :field_name, unique: true
  end
end
```

### 🎯 Controllers de Rails

**Convenciones:**
- Usar `before_action` para autenticación y configuración
- Mantener los métodos delgados (lógica en modelos)
- Usar strong parameters
- Manejar errores apropiadamente

**Ejemplo:**
```ruby
class ResourcesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_resource, only: [:show, :edit, :update, :destroy]

  def index
    @resources = Resource.all
  end

  private

  def set_resource
    @resource = Resource.find(params[:id])
  end

  def resource_params
    params.require(:resource).permit(:field1, :field2)
  end
end
```

### 📝 Vistas (ERB)

**Convenciones:**
- Usar partials para componentes reutilizables
- Prefijo `_` para partials
- Mantener la lógica en helpers o modelos
- Usar `link_to` y `button_to` en lugar de HTML puro

**Estructura:**
```
app/views/
  ├── layouts/
  │   └── application.html.erb
  ├── shared/
  │   └── _navbar.html.erb
  └── resources/
      ├── index.html.erb
      ├── show.html.erb
      └── _form.html.erb
```

### 🔐 Autenticación

- **Gema:** Devise
- **Usuario actual:** `current_user`
- **Verificar autenticación:** `user_signed_in?`
- **Proteger acciones:** `before_action :authenticate_user!`

### 🚀 Turbo y Hotwire

- El proyecto usa **Turbo** para navegación SPA
- Usar `data: { turbo_confirm: "mensaje" }` para confirmaciones
- Usar `data: { turbo_submits_with: "texto" }` para feedback en forms

### 📦 Dependencias

**Verificar antes de agregar nuevas gemas:**
1. Revisar `Gemfile` para evitar duplicados
2. Preferir soluciones nativas de Rails cuando sea posible
3. Documentar por qué se necesita la gema

### 🧪 Testing

- Escribir tests cuando sea apropiado
- Ubicación: `test/` (Minitest por defecto)
- Ejecutar con: `rails test`

### 📋 Tareas Rake

- Ubicación: `lib/tasks/`
- Usar namespace descriptivo
- Agregar descripción con `desc`

**Ejemplo:**
```ruby
namespace :projects do
  desc "Descripción de la tarea"
  task nombre_tarea: :environment do
    # código
  end
end
```

### 🎨 Patrones de Diseño

**Preferir:**
- Fat Models, Skinny Controllers
- Service Objects para lógica compleja
- Concerns para código compartido
- Decorators/Presenters para lógica de vista

### 🔍 Debugging

**Herramientas disponibles:**
- `rails console` - Consola interactiva
- `rails dbconsole` - Consola de base de datos
- `binding.pry` - Breakpoints (si está disponible)
- `rails routes` - Ver todas las rutas

### 📚 Recursos del Proyecto

**Modelos principales:**
- `User` - Usuarios (Devise)
- `Project` - Proyectos
- `ProjectUser` - Relación usuarios-proyectos (roles: owner, member)
- `Todo` - Listas de tareas
- `Task` - Tareas individuales
- `Document` - Documentos
- `Announcement` - Anuncios

**Asociaciones importantes:**
- Un proyecto tiene muchos usuarios a través de `project_users`
- Un proyecto tiene un owner (rol especial en `project_users`)
- Los proyectos tienen todos, documentos, anuncios, etc.

### ✅ Checklist antes de Commit

- [ ] No hay JavaScript inline
- [ ] Los Stimulus controllers están bien estructurados
- [ ] Las migraciones se ejecutaron correctamente
- [ ] Las rutas están definidas correctamente
- [ ] Los tests pasan (si aplica)
- [ ] El código sigue las convenciones de Rails
- [ ] No hay código comentado innecesario
- [ ] Las vistas usan Tailwind CSS apropiadamente

### 🎯 Prioridades

1. **Funcionalidad** - Que funcione correctamente
2. **Convenciones** - Seguir las reglas de Rails y este proyecto
3. **Limpieza** - Código limpio y mantenible
4. **Performance** - Optimizar cuando sea necesario

---

## Ejemplos Específicos del Proyecto

### Dropdown Menu (Flowbite + Stimulus)

```erb
<div data-controller="dropdown" class="relative">
  <button 
    data-dropdown-target="button"
    data-action="click->dropdown#toggle">
    Menu
  </button>
  
  <div data-dropdown-target="menu" class="hidden">
    <!-- items -->
  </div>
</div>
```

### Copiar al Portapapeles

```erb
<div data-controller="clipboard">
  <input 
    data-clipboard-target="source" 
    value="texto a copiar"
    readonly
  />
  <button data-action="click->clipboard#copy">
    Copiar
  </button>
</div>
```

### Invitaciones a Proyectos

- Los proyectos tienen `invitation_token` único
- URL: `/invite/:token`
- Cualquier usuario puede unirse con el link
- El owner puede regenerar el token

---

**Última actualización:** Noviembre 2024
