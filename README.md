# TEBOOK  simple planning project app

With Tebook you can create, manage and share your tasks and projects

## Prerequisites

The best way to run the project is using Docker

## Install

1. Clone the repository
2. Run `docker-compose up`
3. Run `docker-compose run web rails db:create`
4. Run `docker-compose run web rails db:migrate`

# Register first user

1. Run `docker-compose run web rails db:seed`
2. Go to `localhost:3000` in your browser
3. Register a new user

navigate to 

http://localhost:3000/registers/new
