# TEBOOK  simple planning project app
<img width="1440" alt="Screenshot 2025-06-28 at 6 00 27 PM" src="https://github.com/user-attachments/assets/9df1313e-7478-4a3d-9a6d-e23fc3934df9" />

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
