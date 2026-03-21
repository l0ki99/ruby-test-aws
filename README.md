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


## Candidate Notes

### General 

On starting this test, I had limited knowledge of React/Vite and no experience with Ruby or Ruby on Rails.

I used Claude Code extensively to survey the existing codebase, understand the changes that were needed for each of the tasks, identify additional areas of improvement and write the code itself. I made all architectural, database and design decisions and in all cases I thought through its suggestions and reviewed all changes before committing. In many cases I asked Claude for more information on its suggestions, to provide additional technical documentation links and outline other options before proceeding down a particular path. I am ultimately responsible for the code.

All individual tasks were bundled into their own branch for ease of tracability and I ensured detailed commit notes were made for each. I did not create a PR for each merge to the dev branch, however in a real-world scenario this would be the case.

All tasks were fully completed (including the stretch goal) and all necessary unit tests were implemented and pass. I have detailed notes on all task implementation details and decision points to share in the follow-up interview.

### Improvements and Uncertainties

In all, I found this test to be clearly written and easy to follow. The original codebase was clean (except for the parts that were expected to be optimized) and naming conventions were followed diligently which helped a newcomer come up to speed more quickly.

One very obvious uncertainty was what to do with users and user authentication. Some of the database schema imply that this would be a multiuser application (the existance of a User table and user_id keys in the Posts and Comments tables), however there was no "following" table to match users to each other, which implies more of a "bulletin board" application. As well, the existing UI suggests that user implementation was to be left out of scope. I ultimately made the decision not to implement a user authentication scheme, however I did evaluate different options with Claude.

For the stretch goal, the resolver backend is implemented, but no front end was developed. As well, should this change move forward, I would rename the post_resolver* files to all_post_resolver* for clarity.