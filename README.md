# Tivo  simple planning project app
<img width="1920" height="1045" alt="imagen" src="https://github.com/user-attachments/assets/6000f88d-43a9-4219-82fb-47a8aa7e8463" />

## Kamban board
<img width="1920" height="1045" alt="imagen" src="https://github.com/user-attachments/assets/f067208d-8a91-4f78-a9d9-dea6f91053d5" />

With Tivo you can create, manage and share your tasks and projects

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

http://localhost:3000/users/sign_up


If you have problems with styles

```bash
bin/rails tmp:cache:clear
bin/rails assets:clobber
bin/rails assets:precompile
```

## Production stuffs

In production you will into terminal in dock ploy and run manual migration
