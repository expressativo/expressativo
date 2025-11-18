# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Tivo is a Rails 8 project management application that allows users to create, manage, and share tasks and projects. It's a collaborative platform with projects, todos, tasks, documents, and announcements.

## Database Configuration

- **Development**: MySQL 8.0 (via Docker container in local.yml)
- **Production**: MySQL 8.0
- **Test**: SQLite (configured in database.yml)
- Database credentials are in environment variables: `DB_NAME`, `DB_USERNAME`, `DB_PASSWORD`, `DB_HOST`, `DB_PORT`
- Development defaults: database=tebook_local_db, user=expressativo, password=expressativo, host=127.0.0.1, port=3306

## Development Commands

### Setup & Running
```bash
# Start MySQL database (required for development)
docker-compose -f local.yml up -d

# Initial setup
bin/setup

# Run development server with Tailwind CSS watching (preferred method)
bin/dev

# Or run server manually
bin/rails server

# Watch Tailwind CSS in separate terminal
bin/rails tailwindcss:watch
```

### Database Operations
```bash
# Create database
bin/rails db:create

# Run migrations
bin/rails db:migrate

# Rollback migration
bin/rails db:rollback

# Seed database (creates first user)
bin/rails db:seed

# Reset database
bin/rails db:reset
```

### Testing
```bash
# Run all tests
bin/rails test

# Run specific test file
bin/rails test test/models/project_test.rb

# Run specific test
bin/rails test test/models/project_test.rb:10

# Run system tests
bin/rails test:system
```

### Code Quality
```bash
# Run RuboCop linter
bin/rubocop

# Auto-correct offenses
bin/rubocop -a

# Security analysis
bin/brakeman
```

### Asset Management
```bash
# If styles aren't loading properly
bin/rails tmp:cache:clear
bin/rails assets:clobber
bin/rails assets:precompile
```

## Architecture

### Data Model & Relationships

**Core Entity: Project**
- Projects use a many-to-many relationship with Users through `ProjectUser` join table
- `ProjectUser` has a `role` field (values: "owner" or "member")
- A Project can have one owner and multiple members
- Access project owner via `project.owner` helper method
- Filter projects for a user: `Project.for_user(user)`

**Project Dependencies (all use `dependent: :destroy` or `:nullify`)**:
- `has_many :todos` → each Todo `has_many :tasks`
- `has_many :announcements` → each Announcement `has_many :announcement_comments`
- `has_many :documents` (dependent: :nullify)

**User Model**
- Uses Devise for authentication (`:database_authenticatable, :registerable, :recoverable, :rememberable, :validatable`)
- Has avatar via Active Storage (`has_one_attached :avatar`)
- Avatar validation: max 5MB, only PNG/JPEG
- Related to Projects through `project_users` join table

**Document Model**
- Has attached file via Active Storage (`has_one_attached :file`)
- Has enum status: draft, published, archived
- Belongs to a project

### Routing Structure

Nested resources reflect the application hierarchy:
```
/projects/:project_id
  /documents (index, new, create)
  /todos/:todo_id
    /tasks/:task_id
      POST add_comment (task comment)
    GET completed_tasks (todo member route)
  /announcements/:announcement_id
    /announcement_comments
```

Top-level document routes (show, edit, update, destroy) plus:
- GET download
- POST duplicate
- PATCH archive

Root path: `projects#index`

### Authentication & Authorization
- Devise handles user authentication
- Project access controlled via `ProjectUser` join table with role-based permissions
- Use `Project.for_user(user)` scope to get user's accessible projects

### Asset Pipeline
- Uses Propshaft (modern Rails asset pipeline)
- Tailwind CSS 4.x for styling (via tailwindcss-rails and tailwindcss-ruby gems)
- JavaScript via importmap-rails (no Node.js required)
- Hotwire (Turbo + Stimulus) for interactivity

### Storage
- Active Storage for file uploads (avatars, document files)
- AWS S3 configured in production (aws-sdk-s3 gem)
- Storage configuration in config/storage.yml

### Background Jobs & Caching
- Solid Queue for background jobs (database-backed)
- Solid Cache for Rails.cache (database-backed)
- Solid Cable for Action Cable (database-backed)

### Deployment
- In production, run migrations manually in the deployed container

## Testing Approach
- Standard Rails minitest framework
- Tests run in parallel by default
- Fixtures in test/fixtures/*.yml
- System tests use Capybara + Selenium WebDriver

## User Registration
First user registration: navigate to http://localhost:3000/users/sign_up

## Important Notes
- The project was originally named "expressativo" but the app is called "Tivo"
- Recent migrations (Sept-Oct 2025) migrated from has_secure_password to Devise and from direct User-Project association to ProjectUser join table
- Database setup requires Docker MySQL container running (local.yml) for development
