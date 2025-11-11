# Plan de Migración: Consolidar Publicaciones y Tareas

**Fecha:** 2025-11-11
**Estado:** Propuesta
**Autor:** Análisis con Claude Code

---

## 📋 Resumen Ejecutivo

Este documento describe el plan para consolidar las entidades `Publication` y `Task` en un solo modelo (`Task`), simplificando la arquitectura de la aplicación y eliminando la duplicación de código y sincronización bidireccional.

### Problema Actual

- Existe duplicación entre `Publication` y `Task`
- Sincronización bidireccional compleja (cuando se edita uno, se actualiza el otro)
- Confusión sobre cuándo crear una publicación vs una tarea
- Publicaciones auto-crean tareas "fantasma" en el Todo "Publicaciones"
- El calendario solo muestra publicaciones, no tareas con fecha

### Resultado Esperado

- Un solo modelo (`Task`) con campo `task_type` para diferenciar tipos
- Calendario muestra TODAS las tareas con fecha (publicaciones y tareas regulares)
- Eliminación de código duplicado y sincronización
- Simplificación del modelo de datos

---

## 🔍 Análisis de la Situación Actual

### Esquema Actual

**Publications:**
```ruby
# Tabla: publications
- title (string)
- description (text)
- publication_date (date)
- project_id (foreign key)
- task_id (foreign key, optional)
- created_by_id (foreign key)
```

**Tasks:**
```ruby
# Tabla: tasks
- title (string)
- done (boolean)
- todo_id (foreign key) # REQUIRED
- created_by_id (foreign key)
- notes (text, rich text)
- due_date (datetime)
- column_id (foreign key, optional)
- position (integer)
```

### Relación Actual

```
Publication (1) --- (0..1) Task
  - after_create: crea Task automáticamente en Todo "Publicaciones"
  - after_update: sincroniza título con Task

Task (1) --- (0..1) Publication
  - after_update: sincroniza título con Publication
  - dependent: :destroy
```

### Archivos Involucrados

**Modelos:**
- `/app/models/publication.rb`
- `/app/models/task.rb`

**Controladores:**
- `/app/controllers/publications_controller.rb`
- `/app/controllers/tasks_controller.rb`

**Vistas:**
- `/app/views/publications/index.html.erb` (calendario)
- `/app/views/projects/_publications.html.erb` (widget)
- `/app/views/tasks/` (múltiples vistas)

**JavaScript:**
- `/app/javascript/controllers/calendar_controller.js`

**Migraciones:**
- `/db/migrate/20251108231158_create_publications.rb`
- `/db/migrate/20250513212609_create_tasks.rb`

---

## 🎯 Objetivos de la Migración

1. ✅ Consolidar Publication y Task en un solo modelo
2. ✅ Eliminar duplicación de código
3. ✅ Remover sincronización bidireccional
4. ✅ Mostrar tareas Y publicaciones en el calendario
5. ✅ Mantener toda la funcionalidad existente
6. ✅ Migrar datos existentes sin pérdida

---

## 📝 Plan de Migración Detallado

### Fase 1: Preparar el Modelo Task

#### 1.1 Crear Migración para Agregar Campos a Task

```bash
bin/rails generate migration AddPublicationFieldsToTasks task_type:integer publication_date:date
```

**Migración:**
```ruby
class AddPublicationFieldsToTasks < ActiveRecord::Migration[8.0]
  def change
    # Agregar tipo de tarea (0: regular, 1: publication)
    add_column :tasks, :task_type, :integer, default: 0, null: false
    add_index :tasks, :task_type

    # Agregar fecha de publicación (usaremos este en lugar de due_date para publicaciones)
    add_column :tasks, :publication_date, :date

    # Hacer todo_id opcional (para que publicaciones puedan existir sin Todo padre)
    change_column_null :tasks, :todo_id, true

    # Agregar descripción simple (para compatibilidad con publications)
    add_column :tasks, :description, :text
  end
end
```

#### 1.2 Actualizar el Modelo Task

```ruby
# app/models/task.rb
class Task < ApplicationRecord
  include TrackableActivity

  # Enums
  enum task_type: { regular: 0, publication: 1 }

  # Relaciones
  belongs_to :todo, optional: true  # Ahora es opcional
  belongs_to :created_by, class_name: "User"
  belongs_to :column, optional: true
  belongs_to :project # Agregar relación directa con proyecto

  has_rich_text :notes
  has_many :comments, dependent: :destroy

  # ELIMINAR: has_one :publication (ya no existe)

  # Validaciones
  validates :title, presence: true
  validates :done, inclusion: { in: [true, false] }
  validates :publication_date, presence: true, if: :publication?
  validates :todo_id, presence: true, if: :regular?

  # Scopes
  scope :for_calendar, -> {
    where.not(publication_date: nil)
    .or(where.not(due_date: nil))
  }
  scope :publications, -> { where(task_type: :publication) }
  scope :regular_tasks, -> { where(task_type: :regular) }
  scope :for_month, ->(year, month) {
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month
    where(publication_date: start_date..end_date)
      .or(where(due_date: start_date.beginning_of_day..end_date.end_of_day))
  }

  # Métodos
  def completed?
    done
  end

  def saved_change_to_completed?
    saved_change_to_done?
  end

  def scheduled_date
    publication_date || due_date&.to_date
  end

  # ELIMINAR: Métodos de sincronización con Publication
  # private
  # def sync_publication_title
  #   publication&.update_column(:title, title)
  # end
end
```

---

### Fase 2: Migrar Datos Existentes

#### 2.1 Crear Migración de Datos

```bash
bin/rails generate migration MigratePublicationsToTasks
```

**Migración:**
```ruby
class MigratePublicationsToTasks < ActiveRecord::Migration[8.0]
  def up
    # Iterar sobre todas las publicaciones existentes
    Publication.find_each do |publication|
      if publication.task_id.present?
        # Si la publicación ya tiene una tarea asociada, actualizar esa tarea
        task = Task.find(publication.task_id)
        task.update!(
          task_type: :publication,
          publication_date: publication.publication_date,
          description: publication.description,
          project_id: publication.project_id
        )
      else
        # Si no tiene tarea asociada, crear una nueva
        # Buscar o crear el todo "Publicaciones"
        todo = publication.project.todos.find_or_create_by(name: "Publicaciones")

        Task.create!(
          title: publication.title,
          task_type: :publication,
          publication_date: publication.publication_date,
          description: publication.description,
          project_id: publication.project_id,
          todo_id: todo.id,
          created_by_id: publication.created_by_id,
          done: false,
          created_at: publication.created_at,
          updated_at: publication.updated_at
        )
      end
    end

    puts "Migrados #{Publication.count} publicaciones a tareas"
  end

  def down
    # Rollback: recrear publicaciones desde tareas tipo publication
    Task.publications.find_each do |task|
      Publication.create!(
        title: task.title,
        description: task.description,
        publication_date: task.publication_date,
        project_id: task.project_id,
        task_id: task.id,
        created_by_id: task.created_by_id,
        created_at: task.created_at,
        updated_at: task.updated_at
      )
    end
  end
end
```

#### 2.2 Ejecutar Migración

```bash
bin/rails db:migrate
```

---

### Fase 3: Actualizar Controladores y Vistas

#### 3.1 Refactorizar PublicationsController

**Opción A: Renombrar a CalendarController**

```bash
git mv app/controllers/publications_controller.rb app/controllers/calendar_controller.rb
```

```ruby
# app/controllers/calendar_controller.rb
class CalendarController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project

  def index
    @year = params[:year]&.to_i || Date.today.year
    @month = params[:month]&.to_i || Date.today.month

    # Obtener todas las tareas con fecha en el mes seleccionado
    @tasks = @project.tasks.for_month(@year, @month).includes(:created_by, :todo)
    @tasks_by_date = @tasks.group_by { |t| t.publication_date || t.due_date.to_date }
  end

  def create
    @task = @project.tasks.new(task_params)
    @task.task_type = :publication
    @task.created_by = current_user

    # Buscar o crear el todo "Publicaciones"
    todo = @project.todos.find_or_create_by(name: "Publicaciones")
    @task.todo = todo

    respond_to do |format|
      if @task.save
        format.json { render json: @task, status: :created }
      else
        format.json { render json: { errors: @task.errors }, status: :unprocessable_entity }
      end
    end
  end

  def update
    @task = @project.tasks.find(params[:id])

    respond_to do |format|
      if @task.update(task_params)
        format.json { render json: @task, status: :ok }
      else
        format.json { render json: { errors: @task.errors }, status: :unprocessable_entity }
      end
    end
  end

  def update_date
    @task = @project.tasks.find(params[:id])
    new_date = Date.parse(params[:new_date])

    if @task.publication?
      @task.update(publication_date: new_date)
    else
      # Para tareas regulares, mantener la hora del due_date original
      @task.update(due_date: new_date.to_datetime + @task.due_date.seconds_since_midnight.seconds)
    end

    respond_to do |format|
      if @task.save
        format.json { render json: @task, status: :ok }
      else
        format.json { render json: { errors: @task.errors }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @task = @project.tasks.find(params[:id])
    @task.destroy

    respond_to do |format|
      format.json { head :no_content }
    end
  end

  private

  def set_project
    @project = current_user.projects.find(params[:project_id])
  end

  def task_params
    params.require(:task).permit(:title, :description, :publication_date)
  end
end
```

#### 3.2 Actualizar Rutas

```ruby
# config/routes.rb

# Cambiar de:
resources :projects do
  resources :publications, only: [:index, :create, :update, :destroy] do
    member do
      patch :update_date
    end
  end
end

# A:
resources :projects do
  resource :calendar, only: [:show] # Muestra el calendario

  resources :tasks do
    member do
      patch :update_date # Para drag-and-drop en calendario
    end
  end
end
```

#### 3.3 Actualizar Vistas del Calendario

**Renombrar y actualizar vista:**

```bash
git mv app/views/publications app/views/calendar
```

```erb
<!-- app/views/calendar/show.html.erb (antes publications/index.html.erb) -->
<div data-controller="calendar"
     data-calendar-project-id-value="<%= @project.id %>"
     data-calendar-current-year-value="<%= @year %>"
     data-calendar-current-month-value="<%= @month %>">

  <!-- Header con controles de mes/año -->
  <div class="calendar-header">
    <h2><%= Date::MONTHNAMES[@month] %> <%= @year %></h2>
    <!-- Botones de navegación -->
  </div>

  <!-- Grid del calendario -->
  <div class="calendar-grid">
    <% @tasks_by_date.each do |date, tasks| %>
      <div class="calendar-day" data-date="<%= date %>">
        <div class="date-label"><%= date.day %></div>

        <% tasks.each do |task| %>
          <div class="calendar-task <%= task.task_type %> <%= 'done' if task.done %>"
               data-calendar-target="task"
               data-task-id="<%= task.id %>"
               data-task-type="<%= task.task_type %>"
               draggable="true">

            <!-- Indicador de tipo -->
            <span class="task-type-badge">
              <%= task.publication? ? '📅' : '✓' %>
            </span>

            <!-- Título -->
            <span class="task-title"><%= task.title %></span>

            <!-- Info adicional -->
            <% if task.todo %>
              <span class="task-todo"><%= task.todo.name %></span>
            <% end %>
          </div>
        <% end %>
      </div>
    <% end %>
  </div>

  <!-- Modal para crear/editar -->
  <div data-calendar-target="modal" class="hidden">
    <!-- Form modal -->
  </div>
</div>
```

#### 3.4 Actualizar JavaScript del Calendario

```javascript
// app/javascript/controllers/calendar_controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "task", "form"]
  static values = {
    projectId: Number,
    currentYear: Number,
    currentMonth: Number
  }

  connect() {
    console.log("Calendar controller connected")
    this.setupDragAndDrop()
  }

  // Crear nueva tarea/publicación
  async createTask(event) {
    event.preventDefault()
    const formData = new FormData(this.formTarget)

    try {
      const response = await fetch(`/projects/${this.projectIdValue}/tasks`, {
        method: 'POST',
        headers: {
          'X-CSRF-Token': this.getCSRFToken(),
          'Accept': 'application/json'
        },
        body: formData
      })

      if (response.ok) {
        window.location.reload() // O actualizar dinámicamente
      } else {
        const errors = await response.json()
        this.showErrors(errors)
      }
    } catch (error) {
      console.error('Error creating task:', error)
    }
  }

  // Actualizar fecha via drag-and-drop
  async updateTaskDate(taskId, newDate) {
    try {
      const response = await fetch(`/projects/${this.projectIdValue}/tasks/${taskId}/update_date`, {
        method: 'PATCH',
        headers: {
          'X-CSRF-Token': this.getCSRFToken(),
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify({ new_date: newDate })
      })

      if (!response.ok) {
        throw new Error('Failed to update task date')
      }
    } catch (error) {
      console.error('Error updating task date:', error)
      // Revertir el cambio visual si falla
    }
  }

  setupDragAndDrop() {
    // Implementación de drag & drop
    this.taskTargets.forEach(task => {
      task.addEventListener('dragstart', this.handleDragStart.bind(this))
      task.addEventListener('dragend', this.handleDragEnd.bind(this))
    })

    const days = this.element.querySelectorAll('.calendar-day')
    days.forEach(day => {
      day.addEventListener('dragover', this.handleDragOver.bind(this))
      day.addEventListener('drop', this.handleDrop.bind(this))
    })
  }

  handleDragStart(event) {
    event.dataTransfer.effectAllowed = 'move'
    event.dataTransfer.setData('taskId', event.target.dataset.taskId)
    event.target.classList.add('dragging')
  }

  handleDragEnd(event) {
    event.target.classList.remove('dragging')
  }

  handleDragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = 'move'
  }

  async handleDrop(event) {
    event.preventDefault()
    const taskId = event.dataTransfer.getData('taskId')
    const newDate = event.currentTarget.dataset.date

    await this.updateTaskDate(taskId, newDate)
  }

  getCSRFToken() {
    return document.querySelector('[name="csrf-token"]').content
  }
}
```

---

### Fase 4: Actualizar Widget de Publicaciones en Dashboard

```erb
<!-- app/views/projects/_calendar_widget.html.erb (antes _publications.html.erb) -->
<div class="calendar-widget">
  <h3>Calendario del Mes</h3>

  <% current_month_tasks = @project.tasks.for_month(Date.today.year, Date.today.month) %>
  <% tasks_by_date = current_month_tasks.group_by(&:scheduled_date) %>

  <div class="upcoming-tasks">
    <% tasks_by_date.sort.first(5).each do |date, tasks| %>
      <div class="date-group">
        <div class="date"><%= date.strftime("%d %b") %></div>
        <% tasks.each do |task| %>
          <div class="task-item <%= task.task_type %>">
            <span class="badge"><%= task.publication? ? '📅' : '✓' %></span>
            <%= link_to task.title, project_task_path(@project, task) %>
          </div>
        <% end %>
      </div>
    <% end %>
  </div>

  <%= link_to "Ver Calendario Completo", project_calendar_path(@project), class: "btn" %>
</div>
```

---

### Fase 5: Eliminar Código Legacy

#### 5.1 Eliminar Modelo Publication

```bash
git rm app/models/publication.rb
```

#### 5.2 Eliminar Tabla Publications

```bash
bin/rails generate migration DropPublications
```

```ruby
class DropPublications < ActiveRecord::Migration[8.0]
  def up
    drop_table :publications
  end

  def down
    create_table :publications do |t|
      t.string :title
      t.text :description
      t.date :publication_date
      t.references :project, null: false, foreign_key: true
      t.references :task, null: true, foreign_key: true
      t.references :created_by, null: true, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
```

#### 5.3 Limpiar Tests

- Eliminar `/test/models/publication_test.rb`
- Eliminar `/test/controllers/publications_controller_test.rb`
- Actualizar tests de Task para incluir publicaciones

#### 5.4 Actualizar Schema

```bash
bin/rails db:migrate
```

---

## 🧪 Plan de Testing

### Tests a Crear/Actualizar

#### 1. Model Tests

```ruby
# test/models/task_test.rb
test "publication task should have publication_date" do
  task = tasks(:publication_task)
  assert task.publication?
  assert_not_nil task.publication_date
end

test "regular task should have todo_id" do
  task = tasks(:regular_task)
  assert task.regular?
  assert_not_nil task.todo_id
end

test "for_calendar scope includes tasks with dates" do
  tasks = Task.for_calendar
  assert tasks.all? { |t| t.publication_date.present? || t.due_date.present? }
end

test "scheduled_date returns publication_date or due_date" do
  pub_task = tasks(:publication_task)
  assert_equal pub_task.publication_date, pub_task.scheduled_date

  regular_task = tasks(:regular_task)
  assert_equal regular_task.due_date.to_date, regular_task.scheduled_date
end
```

#### 2. Controller Tests

```ruby
# test/controllers/calendar_controller_test.rb
test "should show calendar for project" do
  get project_calendar_url(@project)
  assert_response :success
end

test "should create publication task" do
  assert_difference('Task.publications.count') do
    post project_tasks_url(@project), params: {
      task: {
        title: "New Publication",
        publication_date: Date.today,
        description: "Test description"
      }
    }, as: :json
  end
end

test "should update task date via drag and drop" do
  task = tasks(:publication_task)
  new_date = Date.today + 1.day

  patch update_date_project_task_url(@project, task), params: {
    new_date: new_date
  }, as: :json

  assert_response :success
  task.reload
  assert_equal new_date, task.publication_date
end
```

#### 3. System Tests

```ruby
# test/system/calendar_test.rb
test "viewing calendar" do
  visit project_calendar_url(@project)

  assert_selector "h2", text: Date.today.strftime("%B %Y")
  assert_selector ".calendar-task", minimum: 1
end

test "creating publication from calendar" do
  visit project_calendar_url(@project)

  click_on "Nueva Publicación"

  fill_in "Título", with: "Test Publication"
  fill_in "Fecha", with: Date.today

  click_on "Crear"

  assert_text "Test Publication"
end

test "dragging task to new date" do
  # Requiere JavaScript driver
  # Implementar con Capybara + Selenium
end
```

---

## 🔄 Plan de Rollback

En caso de que la migración falle o se detecten problemas:

### Rollback Rápido (Emergencia)

```bash
# Revertir migraciones
bin/rails db:rollback STEP=3

# Restaurar código desde git
git checkout HEAD -- app/models/task.rb
git checkout HEAD -- app/models/publication.rb
git checkout HEAD -- app/controllers/publications_controller.rb

# Reiniciar servidor
bin/rails restart
```

### Rollback Completo con Recuperación de Datos

```ruby
# La migración MigratePublicationsToTasks incluye método `down`
# que recrea las publicaciones desde tasks tipo publication

bin/rails db:migrate:down VERSION=<timestamp_MigratePublicationsToTasks>
bin/rails db:migrate:down VERSION=<timestamp_AddPublicationFieldsToTasks>
```

---

## ⚠️ Consideraciones y Riesgos

### Riesgos Identificados

1. **Pérdida de Datos**: Migración incorrecta podría perder datos
   - **Mitigación**: Backup completo antes de migrar, método `down` en migraciones

2. **Ruptura de Referencias**: Links/URLs antiguos a publications podrán romperse
   - **Mitigación**: Mantener redirecciones de `/publications/:id` a `/tasks/:id`

3. **Performance**: Queries del calendario podrían ser más lentos
   - **Mitigación**: Índices en `task_type`, `publication_date`, scopes optimizados

4. **Confusión de Usuario**: Cambio de UI podría confundir usuarios
   - **Mitigación**: Mantener indicadores visuales claros (badges, colores)

### Consideraciones Técnicas

- **Índices de Base de Datos**: Asegurar índices en campos usados en queries
- **Validaciones**: task_type=publication requiere publication_date
- **Background Jobs**: Si hay jobs procesando publications, actualizarlos
- **API Externa**: Si hay endpoints externos consumiendo publications, mantener compatibilidad

---

## 📅 Cronograma Sugerido

### Semana 1: Preparación
- ✅ Análisis completo (completado)
- ✅ Documento de plan (este documento)
- [ ] Backup completo de base de datos
- [ ] Branch de feature: `feature/consolidate-publications-tasks`

### Semana 2: Implementación Backend
- [ ] Fase 1: Preparar modelo Task (día 1-2)
- [ ] Fase 2: Migración de datos (día 3-4)
- [ ] Testing de modelos (día 5)

### Semana 3: Implementación Frontend
- [ ] Fase 3: Actualizar controladores (día 1-2)
- [ ] Fase 3: Actualizar vistas (día 3-4)
- [ ] Testing de controllers y vistas (día 5)

### Semana 4: Limpieza y Deploy
- [ ] Fase 4: Actualizar widgets (día 1)
- [ ] Fase 5: Eliminar código legacy (día 2)
- [ ] Testing completo E2E (día 3-4)
- [ ] Deploy a staging (día 5)

### Semana 5: Validación
- [ ] QA en staging
- [ ] Corrección de bugs
- [ ] Deploy a producción
- [ ] Monitoreo

---

## ✅ Checklist de Pre-Deploy

Antes de ejecutar la migración en producción:

- [ ] Backup completo de base de datos
- [ ] Backup de archivos de la aplicación
- [ ] Tests pasando al 100%
- [ ] Revisión de código (code review)
- [ ] Documentación actualizada
- [ ] Plan de rollback verificado
- [ ] Stakeholders notificados
- [ ] Ventana de mantenimiento programada
- [ ] Monitoring y alertas configurados
- [ ] Rollback automático configurado si es posible

---

## 📚 Referencias

### Archivos Principales Afectados

**Modelos:**
- `app/models/task.rb` - Modelo consolidado
- `app/models/publication.rb` - **A ELIMINAR**

**Controladores:**
- `app/controllers/calendar_controller.rb` - Nuevo (reemplaza publications_controller)
- `app/controllers/tasks_controller.rb` - Actualizar
- `app/controllers/publications_controller.rb` - **A ELIMINAR**

**Vistas:**
- `app/views/calendar/` - Nuevo directorio (antes publications)
- `app/views/tasks/` - Actualizar
- `app/views/projects/_calendar_widget.html.erb` - Actualizar

**JavaScript:**
- `app/javascript/controllers/calendar_controller.js` - Actualizar

**Migraciones:**
- `db/migrate/YYYYMMDD_add_publication_fields_to_tasks.rb` - Nueva
- `db/migrate/YYYYMMDD_migrate_publications_to_tasks.rb` - Nueva
- `db/migrate/YYYYMMDD_drop_publications.rb` - Nueva

### Documentación Rails Relacionada

- [Active Record Migrations](https://guides.rubyonrails.org/active_record_migrations.html)
- [Active Record Associations](https://guides.rubyonrails.org/association_basics.html)
- [Routing](https://guides.rubyonrails.org/routing.html)
- [Controllers](https://guides.rubyonrails.org/action_controller_overview.html)

---

## 💬 Notas Finales

Este plan es una guía completa pero flexible. Durante la implementación pueden surgir detalles adicionales que requieran ajustes. La clave es:

1. **Hacer commits pequeños y frecuentes**
2. **Testear cada fase antes de continuar**
3. **Mantener comunicación con stakeholders**
4. **Tener siempre un plan de rollback listo**

**¿Preguntas o necesitas aclaraciones?** Contacta al equipo de desarrollo antes de proceder.

---

**Última actualización:** 2025-11-11
**Estado del plan:** Propuesta pendiente de aprobación
