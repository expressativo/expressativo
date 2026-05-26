# Análisis de vulnerabilidades — Tivo

Fecha del análisis: 2026-05-20
Branch: `feat/javiermora/tenant_config`
Herramientas usadas: revisión manual + `bin/brakeman` (0 warnings — el escáner estático no detecta lógica de autorización, que es donde la app tiene los problemas serios).

## Resumen ejecutivo

El patrón dominante es **broken access control / IDOR**: la tenancy se "confía" al `params[:project_id]` sin verificar membership, y los nested resources (`Task`, `Folder`, `Document`, `Comment`) se cargan con `Model.find(params[:id])` sin scoping al project. La gema `acts_as_tenant` resolvería esto estructuralmente, pero conviene cerrar primero los huecos de autorización para no enmascarar bugs durante la migración.

| Severidad | Total | Resueltos | Pendientes |
|-----------|-------|-----------|------------|
| Crítica   | 8     | 5         | 3          |
| Alta      | 9     | 0         | 9          |
| Media     | 5     | 0         | 5          |
| Baja      | 3     | 0         | 3          |

## Estado por hallazgo

| ID | Severidad | Categoría | Título | Estado |
|----|-----------|-----------|--------|--------|
| C1 | Crítica | Access Control | IDOR: `Project.find` sin validar membership en 8 controllers | ✅ Resuelto (2026-05-20) |
| C2 | Crítica | Access Control | IDOR en `Task.find` directo | ✅ Resuelto (2026-05-20) |
| C3 | Crítica | Access Control | IDOR en `Folder.find` (incluye `parent_folder_id`) | ✅ Resuelto (2026-05-20) |
| C4 | Crítica | Access Control | IDOR en download/duplicate/archive de Document | ✅ Resuelto (2026-05-20) |
| C5 | Crítica | Authorization | Un member puede eliminar el project completo | ⏳ Pendiente |
| C6 | Crítica | Authorization | Un member puede expulsar a otros members | ⏳ Pendiente |
| C7 | Crítica | CSRF + IDOR | `board_tasks#update_position` sin CSRF ni scoping | ⏳ Pendiente |
| C8 | Crítica | XSS | SVG sanitizer custom incompleto | ✅ Resuelto (2026-05-20) |
| A1 | Alta | Tokens | Invitation tokens sin expiración ni rotación | ⏳ Pendiente |
| A2 | Alta | Rate limiting | Sin `Rack::Attack` | ⏳ Pendiente |
| A3 | Alta | Mass assignment | `column_id` en `tasks_params` sin validar | ⏳ Pendiente |
| A4 | Alta | Mass assignment | `parent_folder_id` en `folder_params` sin validar | ⏳ Pendiente |
| A5 | Alta | File upload | Validación de avatar por `content_type` (spoofeable) | ⏳ Pendiente |
| A6 | Alta | File upload | Documentos sin allowlist de tipos ni límite | ⏳ Pendiente |
| A7 | Alta | Secrets | Password de DB con default hardcoded | ⏳ Pendiente |
| A8 | Alta | Defense in depth | CSP deshabilitada | ⏳ Pendiente |
| A9 | Alta | Auth | OmniAuth vincula por email sin verificar `email_verified` | ⏳ Pendiente |
| M1 | Media | Authorization | `regenerate_invitation` sin `return` tras check fallido | ⏳ Pendiente |
| M2 | Media | Info disclosure | `logger.debug` con `params.inspect` | ⏳ Pendiente |
| M3 | Media | Session | Cookie `rememberable` sin flags explícitos | ⏳ Pendiente |
| M4 | Media | XSS | Action Text en email de announcements | ⏳ Pendiente |
| M5 | Media | Crypto | Lookup de invitation_token no usa comparación constant-time | ⏳ Pendiente |
| B1 | Baja | Dependencias | `omniauth-google-oauth2` sin pin de versión | ⏳ Pendiente |
| B2 | Baja | Tooling | Brakeman desactualizado (7.1.0 → 8.0.4) | ⏳ Pendiente |
| B3 | Baja | Tooling | Sin `bundler-audit` / `dependabot` | ⏳ Pendiente |

---

## Hallazgos detallados

### Críticas

#### C1. IDOR masivo: `Project.find(params[:project_id])` sin validar membership

**Ubicaciones**
- `app/controllers/documents_controller.rb:114`
- `app/controllers/folders_controller.rb:65`
- `app/controllers/todos_controller.rb:61`
- `app/controllers/tasks_controller.rb:113`
- `app/controllers/announcements_controller.rb:50`
- `app/controllers/announcement_comments_controller.rb:34`
- `app/controllers/columns_controller.rb:84`
- `app/controllers/comments_controller.rb:45`

```ruby
def set_project
  @project = Project.find(params[:project_id])
end
```

**Por qué**: cualquier usuario autenticado, conociendo un `project_id`, accede a recursos del project ajeno.

**Explotación**: `GET /projects/999/folders` lista carpetas de un project del que el atacante no es miembro.

**Fix**: usar `Project.for_user(current_user).find(params[:project_id])`. Devuelve 404 (`ActiveRecord::RecordNotFound`) si el user no es miembro, igual que pasa con un id inexistente — sin filtrado de información.

---

#### C2. IDOR en `Task.find(params[:id])` directo

**Ubicaciones**: `app/controllers/tasks_controller.rb:10, 34, 37, 52, 67, 87` y `app/controllers/task_assignments_controller.rb:60`.

```ruby
@task = Task.includes(...).find(params[:id])
```

**Por qué**: aunque el `@project` esté scopeado, la tarea se carga sin validar que pertenezca al project. `PATCH /projects/1/todos/1/tasks/999` edita la tarea 999 sin importar a qué project pertenezca.

**Fix**: cargar desde la asociación: `@task = @todo.tasks.find(params[:id])`.

---

#### C3. IDOR en `Folder.find` (incluye `parent_folder_id`)

**Ubicaciones**: `app/controllers/folders_controller.rb:61, 69`.

```ruby
def set_folder
  @folder = Folder.find(params[:id])
end

def set_parent_folder
  @parent_folder = params[:parent_folder_id].present? ? Folder.find(params[:parent_folder_id]) : nil
end
```

**Por qué**: permite mover folders entre projects ajenos o anidar bajo un parent_folder ajeno.

**Fix**: cargar desde `@project.folders.find(...)`.

---

#### C4. IDOR en download/duplicate/archive de Document

**Ubicaciones**: `app/controllers/documents_controller.rb:72-105` + `set_document` en `:110`.

```ruby
def set_document
  @document = Document.find(params.expect(:id))
end
```

**Por qué**: `GET /documents/:id/download` entrega el blob sin verificar project ownership.

**Fix**: cargar el documento via join con projects accesibles:
```ruby
@document = Document.joins(project: :project_users)
                    .where(project_users: { user_id: current_user.id })
                    .find(params.expect(:id))
```

---

#### C5. Un member puede eliminar el project completo

**Ubicación**: `app/controllers/projects_controller.rb:74-78`.

```ruby
def destroy
  @project = Project.for_user(current_user).find(params[:id])
  @project.destroy
end
```

`for_user` incluye members. No hay check de `role == "owner"`.

**Explotación**: un member hace `DELETE /projects/:id` y elimina todo (con `dependent: :destroy` se llevan todos los todos, tasks, documents, announcements, etc.).

**Fix**: introducir una policy (Pundit u objeto simple) que valide `project.owner == current_user` en `destroy`, `archive`, `unarchive`, `update`.

---

#### C6. Un member puede expulsar a otros members

**Ubicación**: `app/controllers/project_members_controller.rb:38-49`.

Solo se valida que el target no sea owner, no que **quien borra** sea owner.

**Fix**: agregar verificación `unless current_user == @project.owner`.

---

#### C7. CSRF bypass + IDOR combinados en `board_tasks#update_position`

**Ubicación**: `app/controllers/board_tasks_controller.rb:3`.

```ruby
skip_before_action :verify_authenticity_token, only: [:update_position]
def update_position
  task = Task.find(params[:id])
  column = Column.find(params[:column_id])
  task.update(column: column, position: params[:position].to_i)
end
```

**Explotación**: un sitio externo puede mover tareas de cualquier usuario logueado, a cualquier columna existente.

**Fix**: quitar el `skip`, o si el cliente JS no envía CSRF token, agregarlo. Scopear `task` y `column` por project del current_user.

---

#### C8. XSS persistente vía SVG inline

**Ubicación**: `app/helpers/documents_helper.rb:71-81` + `lib/svg_sanitizer.rb` + `config/initializers/active_storage.rb:36-37`.

El `SvgSanitizer` custom remueve `<script>`, `<foreignobject>` y atributos `on*`/`href:javascript:`, pero **no cubre**:
- `<style>` con `@keyframes` y URLs `javascript:`
- `<animate attributeName="href" to="javascript:...">`
- `<set>` con atributos peligrosos
- `<use href="#x">` con xlink a externos

Combinado con C1 (IDOR), un no-miembro puede subir el SVG si conoce un `project_id`.

**Fix**: reescribir el sanitizer con **allowlist** de tags y atributos (en vez de blocklist) usando Loofah con un scrubber custom.

---

### Altas

#### A1. Invitation tokens sin expiración ni rotación
`Project#invitation_token` se genera una vez y vive para siempre. Si se filtra (Slack, screenshot), acceso permanente.
**Fix**: agregar `invitation_token_expires_at`, rotación opcional post-uso, y endpoint para revocar.

#### A2. Sin rate limiting
No hay `rack-attack` en Gemfile. Vulnerable a bruteforce de login, enumeración de invitation tokens, spam de invitaciones.
**Fix**: agregar `gem "rack-attack"` con throttles por IP/user en login, password reset, signup, invitaciones.

#### A3. `column_id` en `tasks_params` sin validar pertenencia
`app/controllers/tasks_controller.rb:116`. Combinado con C2, permite mover tareas a columnas ajenas.
**Fix**: validar en el modelo `Task` que `column.board.project_id == todo.project_id`.

#### A4. `parent_folder_id` en `folder_params` sin validar pertenencia
`app/controllers/folders_controller.rb:73`. Permite anidar folder bajo parent de otro project, o crear ciclos.
**Fix**: validación en el modelo `Folder` que `parent_folder.project_id == project_id`.

#### A5. Validación de avatar por `content_type` (spoofeable)
`app/controllers/profiles_controller.rb:30-34` confía en el header HTTP. Sin magic bytes.
**Fix**: usar `marcel` (ya viene con Active Storage) para detección por contenido real.

#### A6. Documentos sin allowlist de tipos ni límite
`app/controllers/documents_controller.rb:123` permite `:file` sin validación.
**Fix**: validación en el modelo `Document` (content_type + tamaño + magic bytes).

#### A7. Password de DB con default hardcoded
`config/database.yml`: `ENV.fetch("DB_PASSWORD") { "expressativo" }` en 7 sitios.
**Fix**: `ENV.fetch("DB_PASSWORD")` sin default. Que falle ruidoso si no se setea.

#### A8. CSP deshabilitada
`config/initializers/content_security_policy.rb` todo comentado. Sin defense-in-depth para C8.
**Fix**: habilitar CSP con `default-src 'self'`, `script-src 'self' 'nonce-...'`, prohibir inline.

#### A9. OmniAuth vincula por email sin verificar `email_verified`
`app/models/user.rb:22-43`. Hoy Google verifica email, pero al añadir otros providers → account takeover trivial.
**Fix**: verificar `auth.info.email_verified` antes de vincular.

---

### Medias

#### M1. `regenerate_invitation` sin `return` tras check fallido
`app/controllers/project_invitations_controller.rb:45`. Hoy no causa daño pero el patrón es frágil.

#### M2. `logger.debug` con `params.inspect`
`app/controllers/tasks_controller.rb:38-39`. Filtra params completos en logs si log_level es debug.

#### M3. Cookie `rememberable` sin flags explícitos
`config/initializers/devise.rb:170`. Fijar `secure: true, httponly: true, same_site: :lax` explícitamente.

#### M4. Action Text en email de announcements
`app/views/announcement_mailer/new_announcement_notification.html.erb:73`. Validar que la sanitización de Action Text no permite `<style>` ni `on*` en emails.

#### M5. Lookup de invitation_token no usa comparación constant-time
`Project.find_by(invitation_token: params[:token])`. Bajo riesgo con tokens de 256 bits, pero notable.

---

### Bajas

#### B1. `omniauth-google-oauth2` sin pin de versión
Riesgo de supply-chain en `bundle update`.

#### B2. Brakeman desactualizado (7.1.0 → 8.0.4)
Falsos negativos por reglas viejas.

#### B3. Sin `bundler-audit` / `dependabot`
No detecta CVEs nuevas en gems.

---

## Plan de remediación

Orden sugerido por relación impacto/riesgo:

1. **C1 + C2 + C3 + C4** — Bloquear el sangrado de tenancy. PRs pequeños, sin migraciones.
2. **C5 + C6 + M1** — Policies por rol (owner vs member).
3. **C7** — CSRF + scoping en board_tasks.
4. **C8** — Reemplazar SvgSanitizer por Loofah con allowlist.
5. **A1** — TTL y rotación de invitation tokens.
6. **A2** — Rack::Attack.
7. **A3 + A4** — Validaciones de pertenencia en modelos.
8. **A5 + A6** — Validación real de archivos (magic bytes).
9. **A7** — Sacar defaults de credenciales.
10. **A8** — Habilitar CSP.
11. **A9** — Verificar `email_verified` en OmniAuth.
12. **M2 + M3 + M4 + M5** — Limpieza.
13. **B1 + B2 + B3** — Tooling de seguridad continua.
14. **Migrar a `acts_as_tenant`** — una vez 1-3 estén hechos, la gema se vuelve cleanup.

---

## Changelog

> Esta sección se actualiza a medida que los hallazgos se solucionan. Cada entrada incluye fecha, hallazgo y commit/PR.

### 2026-05-20

**C1 — IDOR en `set_project` (8 controllers)** ✅
Reemplazado `Project.find(params[:project_id])` por `Project.for_user(current_user).find(...)` en:
- `app/controllers/documents_controller.rb`
- `app/controllers/folders_controller.rb`
- `app/controllers/todos_controller.rb`
- `app/controllers/tasks_controller.rb` (en `set_context`)
- `app/controllers/announcements_controller.rb`
- `app/controllers/announcement_comments_controller.rb`
- `app/controllers/columns_controller.rb`
- `app/controllers/comments_controller.rb`

Ahora un usuario que no es miembro del project recibe 404 en lugar de poder operar sobre recursos ajenos.

**C2 — IDOR en `Task.find` directo** ✅
- `app/controllers/tasks_controller.rb`: extraído `set_task` que carga via `@todo.tasks.find(params[:id])`. Eliminadas las re-asignaciones de `@project`/`@todo` en `show` que pisaban el scoping.
- `app/controllers/task_assignments_controller.rb` (no estaba en la lista original pero tenía el mismo patrón): `set_task` ahora carga `@project → @todo → @task` desde asociaciones. `create` también scopea `@user = @project.users.find(...)` para evitar asignar usuarios externos al project.

**C3 — IDOR en `Folder.find` y `parent_folder_id`** ✅
`app/controllers/folders_controller.rb`: `set_folder` y `set_parent_folder` ahora cargan desde `@project.folders.find(...)`. `documents_controller#set_folder` también.

**C4 — IDOR en download/duplicate/archive de Document** ✅
`app/controllers/documents_controller.rb#set_document` ahora hace:
```ruby
Document.joins(project: :project_users)
        .where(project_users: { user_id: current_user.id })
        .find(params.expect(:id))
```
Un user que no es miembro del project del documento recibe 404, lo que cierra `download`, `duplicate`, `archive`, `show`, `edit`, `update`, `destroy`.

**C8 — SVG sanitizer custom incompleto** ✅
`lib/svg_sanitizer.rb` reescrito con Loofah + scrubber custom usando **allowlist** estricto de tags SVG seguros (sin `<style>`, `<foreignObject>`, ni `<script>`) y filtrado de atributos `on*` y `href`/`xlink:href` con esquemas peligrosos.

Vectores verificados manualmente como bloqueados:
- `<script>` → eliminado
- `onclick="alert(1)"` → atributo eliminado
- `<a href="javascript:alert(1)">` → tag eliminado (`<a>` no está en allowlist)
- `<foreignObject><iframe src="javascript:..."/>` → eliminado
- `<style>circle { fill: url(javascript:...); }</style>` → tag `<style>` eliminado
- `<animate attributeName="href" to="javascript:...">` → eliminado (`<a>` envolvente no en allowlist)
- `<use xlink:href="javascript:...">` → atributo eliminado

SVG legítimos (con `<circle>`, `<rect>`, gradientes, filtros, etc.) se renderizan sin cambios.

### Notas

- **Tests no se pudieron correr**: `config/database.yml` no especifica `adapter` para `test.primary`, error preexistente (`ActiveRecord::AdapterNotSpecified`) que no introdujeron estos cambios. Verificación se hizo con `bin/rails runner` cargando los controllers y ejercitando `SvgSanitizer` contra 9 vectores conocidos. `bin/rubocop` pasa limpio en los 10 archivos modificados.
- **Vulnerabilidad lateral arreglada de paso**: `TaskAssignmentsController` tenía el mismo patrón C2/IDOR y fue corregido aunque no estaba en la lista original.
- **Acceso a usuarios externos**: `TaskAssignmentsController#create` ahora valida que el assignee sea miembro del project (antes hacía `User.find(params[:user_id])` permitiendo asignar a cualquier usuario del sistema).
