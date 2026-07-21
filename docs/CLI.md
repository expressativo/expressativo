# Tivo CLI — Cómo funciona toda la movida

> Una CLI de terminal para interactuar con Tivo desde la consola. Login con OAuth
> (estilo `gh auth login`), gestión de proyectos y tareas, distribuida como
> binario único de 16 MB (sin Python requerido en la máquina destino).

---

## TL;DR — qué construí

| Repositorio           | Qué tiene                                                    |
| --------------------- | ------------------------------------------------------------ |
| `expressativo` (este) | Backend: migración, modelos, controllers API + vista `/cli/authorize` |
| `tivo-cli` (separado) | Paquete Python (Typer + Rich + httpx) + spec PyInstaller + CI |

Flujo en una línea:

```
$ tivo login  →  abre browser  →  te autenticás en Tivo  →  autorizás
             →  la CLI recibe un code  →  lo canjea por token  →  listo
```

---

## Arquitectura

```
┌──────────────────────┐         ┌────────────────────────┐
│   Terminal (CLI)     │         │   Rails (Tivo app)     │
│   tivo (binario)     │         │                        │
│                      │         │  /cli/authorize (web)  │
│  1. tivo login       │ ────►   │  /cli/grant     (web)  │
│     genera PKCE      │         │                        │
│     levanta server   │         │  Devise session        │
│     http en :1455    │         │  (browser)             │
│                      │         │                        │
│  2. recibe code      │ ◄────  │  redirect 127.0.0.1    │
│     vía callback     │         │     ?code=xxx&state=.. │
│                      │         │                        │
│  3. POST /api/v1/    │ ────►   │  valida PKCE + code    │
│     cli_token        │         │  emite access_token    │
│                      │ ◄────  │  {access_token, user}  │
│                      │         │                        │
│  4. GET /api/v1/...  │ ────►   │  Authorization:        │
│     con Bearer token │         │    Bearer <token>      │
└──────────────────────┘         └────────────────────────┘
        │                                  │
        └───── ~/.config/tivo/config.toml ─┘
                  (token + state local)
```

---

## Flujo de login paso a paso

1. **CLI** genera `code_verifier` (random 64 bytes) y `code_challenge = SHA256(verifier)` (S256).
2. **CLI** levanta un servidor HTTP efímero en `http://127.0.0.1:1455/` (rango 1455-1498).
3. **CLI** abre el navegador en `/cli/authorize?client_id=tivo-cli&redirect_uri=...&code_challenge=...&state=...`.
4. Si el usuario **no** tiene sesión Devise → Rails lo redirige a `/users/sign_in`.
5. Tras login, Rails muestra la página de **consentimiento** (`app/views/cli/authorize.html.erb`).
6. El usuario clickea **"Autorizar acceso"** → `POST /cli/grant` → Rails crea un `CliAuthorizationCode` (5 min de vida, un solo uso) y redirige al `redirect_uri` con `?code=xxx&state=xxx`.
7. El servidor local de la CLI recibe el callback, valida `state`, extrae `code`.
8. **CLI** hace `POST /api/v1/cli_token` con `{ code, code_verifier, redirect_uri }`.
9. Rails verifica PKCE (`SHA256(verifier) == code_challenge`), consume el code, crea un `CliAccessToken` y devuelve `{ access_token, user }`.
10. **CLI** guarda el token en `~/.config/tivo/config.toml` (permisos `0600`).

> Segunda vez: si ya tenés sesión Devise, te saltea el login y vas directo a la página de consentimiento.

---

## Endpoints

### Web (browser, sesión Devise)

| Método | Path             | Controller#action      |
| ------ | ---------------- | ---------------------- |
| GET    | `/cli/authorize` | `cli#authorize`        |
| POST   | `/cli/grant`     | `cli#grant`            |
| POST   | `/cli/deny`      | `cli#deny`             |

### API v1 (JSON, Bearer token)

| Método | Path                                  | Descripción                          |
| ------ | ------------------------------------- | ------------------------------------ |
| POST   | `/api/v1/cli_token`                   | Intercambiar code por access_token   |
| GET    | `/api/v1/me`                          | Usuario autenticado                  |
| GET    | `/api/v1/projects`                    | Listar proyectos del usuario         |
| GET    | `/api/v1/projects/:id`                | Detalle + listas (todos)             |
| GET    | `/api/v1/projects/:project_id/todos`  | Listar todos                         |
| GET    | `/api/v1/todos/:todo_id/tasks`        | Listar tareas (filtro `?status=`)    |
| POST   | `/api/v1/todos/:todo_id/tasks`        | Crear tarea                          |
| GET    | `/api/v1/tasks/:id`                   | Detalle de tarea                     |
| PATCH  | `/api/v1/tasks/:id`                   | Actualizar tarea                     |
| DELETE | `/api/v1/tasks/:id`                   | Eliminar tarea                       |

Todas las rutas bajo `/api/v1` requieren header `Authorization: Bearer <token>` (salvo `POST /cli_token`).

---

## Modelos (backend)

### `CliAccessToken`

| Columna        | Tipo        | Notas                                  |
| -------------- | ----------- | -------------------------------------- |
| `id`           | bigint      |                                        |
| `user_id`      | bigint (FK) |                                        |
| `token_digest` | string      | `SHA256(raw_token)` — único, indexado  |
| `name`         | string      | Etiqueta legible (`tivo-cli · ana@host`) |
| `scopes`       | string      | Default: `"read write"`                |
| `last_used_at` | datetime    | Se actualiza en cada request           |
| `expires_at`   | datetime    | Nullable (sin expiración por default)  |
| `revoked_at`   | datetime    | Cuando se revocó manualmente           |

Métodos clave:

```ruby
CliAccessToken.authenticate(raw_token)  # devuelve token o nil, actualiza last_used_at
token.revoke!                            # marca revoked_at = Time.current
token.active?                            # revoked_at.nil? && (expires_at.nil? || future)
```

**El raw_token se muestra UNA sola vez** al crearse (en la respuesta de `/api/v1/cli_token`). Después solo queda el digest.

### `CliAuthorizationCode`

| Columna                | Tipo        | Notas                                       |
| ---------------------- | ----------- | ------------------------------------------- |
| `code_digest`          | string      | `SHA256(raw_code)`                          |
| `user_id`              | bigint (FK) |                                             |
| `redirect_uri`         | string      | Solo `http://` a `localhost` / `127.0.0.1`  |
| `code_challenge`       | string      | PKCE challenge (S256)                       |
| `code_challenge_method`| string      | `"S256"`                                    |
| `expires_at`           | datetime    | 5 minutos desde creación                    |

`CliAuthorizationCode.consume!(raw_code, verifier:)` valida PKCE, chequea expiración y **destruye** el code si todo OK (single-use).

---

## CLI — estructura del repo

```
tivo-cli/
├── pyproject.toml                 # entrypoint: tivo = tivo_cli.main:app
├── README.md
├── scripts/
│   ├── tivo.spec                  # PyInstaller spec → binario standalone
│   ├── build.sh                   # build local: lint + pyinstaller
│   └── install.sh                 # curl ... | bash (GitHub Releases)
├── .github/workflows/release.yml  # CI: linux x64 + macos x64 + macos arm64
└── tivo_cli/
    ├── main.py                    # app Typer + alias `tivo login/logout/whoami`
    ├── auth.py                    # PKCE + servidor HTTP local
    ├── client.py                  # wrapper httpx + ApiError
    ├── config.py                  # ~/.config/tivo/config.toml (0600)
    ├── ui.py                      # helpers Rich (tablas, spinners, prompts)
    └── commands/
        ├── auth.py                # login, logout, whoami, config
        ├── projects.py            # list, use, show
        └── tasks.py               # list, new, show, edit, done, todo, rm
```

### Comandos disponibles

```bash
# Sesión
tivo login [--api-url URL] [--no-browser]
tivo logout
tivo whoami
tivo status
tivo auth config

# Proyectos
tivo projects list
tivo projects use <ID>
tivo projects show

# Tareas
tivo tasks list [--todo ID] [--status pending|in_progress|done]
tivo tasks new [-t "Título"] [--todo ID] [--due YYYY-MM-DD] [--status X] [--notes X]
tivo tasks show <ID>
tivo tasks edit <ID> [--title X] [--status X] [--due X] [--notes X]
tivo tasks done <ID>
tivo tasks todo <ID>
tivo tasks rm <ID> [-f]
```

Todos los comandos `tasks` operan sobre el **proyecto activo** (definido con `tivo projects use`).

---

## Configuración

Archivo: `~/.config/tivo/config.toml` (permisos `0600`)

```toml
api_url = "https://tivo.miequipo.com"

[auth]
access_token = "tt_..."
user_email = "ana@miequipo.com"
user_name  = "Ana Pérez"

[state]
current_project_id    = 42
current_project_title = "Marketing 2026"
```

Overrides:
- `TIVO_CONFIG_DIR` → cambia el directorio del config (para tests).
- `TIVO_API_URL` → cambia la URL del backend.
- Flag `--api-url` en `tivo login` → setea y persiste.

---

## Seguridad

| Riesgo                        | Mitigación                                                              |
| ----------------------------- | ----------------------------------------------------------------------- |
| Token robado de la DB         | Solo se guarda `SHA256(token)` (digest). Imposible reversar.            |
| Token robado del disco        | `~/.config/tivo/config.toml` con permisos `0600` (solo owner).          |
| MITM en el callback           | `redirect_uri` restringido a `http://127.0.0.1:<puerto>/` (localhost).  |
| CSRF en `/cli/grant`          | CSRF token de Rails + misma sesión Devise.                              |
| Code interceptado             | Expira a los 5 min, un solo uso, validado con PKCE.                     |
| Code reusado                  | Se destruye al consumirlo; segunda solicitud → HTTP 422.                |
| Cliente falso                 | `client_id` validado contra `CLIENT_REGISTRY` en `CliController`.       |
| State mismatch                | CLI genera `state` aleatorio y lo valida en el callback antes de usar el code. |

---

## Cómo se distribuye

### Binario standalone (recomendado)

GitHub Actions construye 3 binarios cuando creás un tag `v*`:

- `tivo-linux-x86_64`
- `tivo-macos-x86_64`
- `tivo-macos-arm64`

Instalación para el usuario final:

```bash
curl -fsSL https://raw.githubusercontent.com/USER/tivo-cli/main/scripts/install.sh | bash
```

Descarga el binario correcto a `~/.local/bin/tivo` y lo deja listo.

### pipx / uv (avanzado)

```bash
pipx install tivo-cli
# o
uv tool install tivo-cli
```

Requiere Python ≥ 3.10 en la máquina destino.

### Desde el repo (desarrollo)

```bash
git clone https://github.com/USER/tivo-cli
cd tivo-cli
pipx install .
```

---

## Cómo probarlo (resumen)

Levantar backend:

```bash
docker compose -f local.yml up -d
bin/rails server
```

Probar CLI:

```bash
# En otra terminal
alias tivo=/path/al/binario_o_venv
tivo login --api-url http://127.0.0.1:3000
tivo projects list
tivo projects use <ID>
tivo tasks list
tivo tasks new -t "Probar CLI" --todo <ID>
tivo tasks done <ID>
```

Para el plan de prueba detallado (casos de error, edge cases, etc.), ver
[`docs/CLI_TESTING.md`](./CLI_TESTING.md) (TODO: crear cuando esté completo).

---

## Decisiones de diseño

### ¿Por qué OAuth-ish y no solo "POST email/password → token"?

- **No exponer credenciales**: la CLI nunca ve la password del usuario.
- **Consentimiento explícito**: el usuario ve en el browser qué permisos pide la CLI.
- **Revocable**: el token se puede borrar desde la web sin cambiar la password.
- **Estándar**: cualquier developer reconoce el flujo (`gh`, `railway`, `vercel` lo usan).

### ¿Por qué PKCE?

PKCE (Proof Key for Code Exchange) evita que un atacante intercepte el `redirect`
y robe el code. Aunque sea localhost, es defensa en profundidad: si otra app local
intentara capturar el callback, no podría canjear el code sin el `verifier`.

### ¿Por qué un repo separado para la CLI?

- Build pipeline distinto (Python vs Ruby).
- Release independiente del backend.
- Usuarios finales no necesitan clonar Rails.
- Permite publicar en PyPI sin atar al repo del backend.

### ¿Por qué Typer + Rich + httpx?

- `typer`: API declarativa, autocompletado en shell gratis, help automático.
- `rich`: tablas, spinners, colores — todo out-of-the-box.
- `httpx`: API moderna, soporta HTTP/2, sync y async con la misma API.

### ¿Por qué binario PyInstaller y no `.py`?

- "Install and done" sin pedir Python al usuario.
- Arranque más rápido (sin importar toda la stdlib cada vez).
- Permite distribuir vía `curl ... | bash` (low friction).

---

## Roadmap / futuras mejoras

- [ ] **Vista web de "Tokens de la CLI"** en `/profile` (lista + revoke).
- [ ] **Tests automatizados** del backend (Minitest) y CLI (pytest).
- [ ] Soporte de **tareas asignadas** (`tivo tasks assign @user`).
- [ ] Soporte de **comentarios** (`tivo tasks comment <ID> "..."`).
- [ ] Modo `--json` para scripting (salida parseable).
- [ ] Autocompletado shell (`tivo --install-completion`).
- [ ] Multi-cuenta (`tivo profiles switch`).
- [ ] Tokens con expiración configurable (`tivo login --ttl 30d`).

---

## Archivos clave

### Backend (`expressativo/`)

```
db/migrate/20260720000001_create_cli_access_tokens_and_authorization_codes.rb
app/models/cli_access_token.rb
app/models/cli_authorization_code.rb
app/controllers/concerns/api_authenticable.rb
app/controllers/cli_controller.rb
app/controllers/api/v1/base_controller.rb
app/controllers/api/v1/cli_token_controller.rb
app/controllers/api/v1/me_controller.rb
app/controllers/api/v1/projects_controller.rb
app/controllers/api/v1/todos_controller.rb
app/controllers/api/v1/tasks_controller.rb
app/views/cli/authorize.html.erb
app/views/api/v1/{projects,todos,tasks}/*.json.jbuilder
config/routes.rb  # nuevas rutas /cli/* y /api/v1/*
```

### CLI (`tivo-cli/`)

```
pyproject.toml
tivo_cli/main.py        # app Typer + alias
tivo_cli/auth.py        # flujo OAuth + PKCE
tivo_cli/client.py      # HTTP client
tivo_cli/config.py      # ~/.config/tivo/config.toml
tivo_cli/commands/      # auth, projects, tasks
scripts/tivo.spec       # PyInstaller
scripts/install.sh      # install vía curl|bash
.github/workflows/release.yml
```

---

**Última actualización:** julio 2026
