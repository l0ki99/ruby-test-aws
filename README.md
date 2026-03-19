# Jobber Take-Home Assessment

This assessment is built using the main pieces of our technology stack (Rails, Graphql, React, Typescript, Tanstack Router, Vite, Vitest).

## Automatic Startup (if you don't want to run Ruby yourself)

Install the latest version of [Docker](https://www.docker.com/), and the latest version of [NodeJS](https://nodejs.org/en).

Then from a CLI/Terminal where the assessment files are located:

1. `docker-compose up --build`

Wait for Puma to load in the terminal and then in a new CLI/Terminal (first time only):

1. `docker-compose exec backend bundle exec rails db:migrate`
1. `docker-compose exec backend bundle exec rails db:seed`
1. `cd frontend && npm install`

The starter application can be viewed at `http://localhost:8091` (after starting the frontend server).

Note: Frontend/Vite HMR/Reloading is a little slow via Docker but it does work. Using the manual setup will get you a faster dev cycle.

## Manual Startup (if you are okay running ruby + bundler + node yourself)

Make sure to have the latest version of [Ruby](https://www.ruby-lang.org/en/) + [Bundler](https://bundler.io/) + [NodeJS](https://nodejs.org/en)

From a CLI/Terminal where the assessment files are located:

1. `cd backend`
1. `bundle install`
1. `rails db:migrate db:seed`
1. `rails s`

and in another terminal:

1. `cd frontend`
1. `npm install`
1. `npm run dev`

The starter application can be viewed at `http://localhost:8091` (after starting the frontend server).
