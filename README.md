# Tivo

A collaborative project management app built with Rails 8. Create projects, manage tasks on kanban boards, chat with your team, and keep everything in one place.

<img width="1920" height="1045" alt="Dashboard" src="https://github.com/user-attachments/assets/6000f88d-43a9-4219-82fb-47a8aa7e8463" />

<img width="1920" height="1045" alt="Kanban board" src="https://github.com/user-attachments/assets/f067208d-8a91-4f78-a9d9-dea6f91053d5" />

## Features

- **Projects & Tasks** — organize work into projects, todos, and tasks with status tracking
- **Kanban Board** — drag-and-drop columns (pending → in progress → done) synced with task status
- **Team Chat** — channels and direct messages with mentions, emoji reactions, and markdown support
- **Documents** — rich text editor with folder organization and file attachments
- **Announcements** — project-wide posts with comments
- **Notifications** — real-time web push notifications
- **Activity Feed** — audit trail of all changes across a project
- **Quick Notes** — personal sticky notes per user
- **Google OAuth** — sign in with Google in addition to email/password

## Tech Stack

- **Rails 8** with Hotwire (Turbo + Stimulus) — no Node.js build step
- **Tailwind CSS 4.x** for styling
- **MySQL 8** (development & production), SQLite (test)
- **Solid Stack** — Solid Queue, Cache, and Cable (database-backed, no Redis needed)
- **Active Storage** + AWS S3 for file uploads
- **Devise** for authentication with Google OAuth2

## Prerequisites

- Ruby 3.3.4
- Docker (for the MySQL database)

## Local Development

```bash
# 1. Clone the repo
git clone <repo-url>
cd tivo

# 2. Start the MySQL container
docker-compose -f local.yml up -d

# 3. Install dependencies and set up the database
bin/setup

# 4. Start the server with Tailwind watcher
bin/dev
```

Then visit [http://localhost:3000/users/sign_up](http://localhost:3000/users/sign_up) to register the first user.

### Environment Variables

Copy `.env.example` to `.env` and fill in the values (if applicable), or configure directly:

| Variable | Description |
|---|---|
| `DB_NAME` | Database name (default: `tebook_local_db`) |
| `DB_USERNAME` | MySQL user (default: `expressativo`) |
| `DB_PASSWORD` | MySQL password (default: `expressativo`) |
| `DB_HOST` | MySQL host (default: `127.0.0.1`) |
| `DB_PORT` | MySQL port (default: `3306`) |
| `GOOGLE_CLIENT_ID` | Google OAuth client ID |
| `GOOGLE_CLIENT_SECRET` | Google OAuth client secret |

## Testing

```bash
# Run all tests
bin/rails test

# Run a specific test file
bin/rails test test/models/project_test.rb

# Run system tests
bin/rails test:system
```

Tests use SQLite — no database container needed.

## Code Quality

```bash
bin/rubocop        # Lint
bin/rubocop -a     # Auto-correct
bin/brakeman       # Security scan
```

## Troubleshooting

If styles aren't loading after changes:

```bash
bin/rails tmp:cache:clear
bin/rails assets:clobber
bin/rails assets:precompile
```

## Production

The app ships as a Docker image. After deploying, run migrations manually:

```bash
rails db:migrate
```

Required production environment variables: `RAILS_MASTER_KEY`, `DB_*` credentials, `AWS_*` for S3, and a Resend API key for email.
