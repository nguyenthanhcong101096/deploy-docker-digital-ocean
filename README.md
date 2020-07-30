# [Deploy with Docker and Digital Ocean](https://coderjourney.com/deploy-docker-digital-ocean/)

## Goal for this Tutorial
- Create a Docker host with docker-machine.
- Deploy a Ruby on Rails application to the server using docker-compose.

## Our Rails Application
The first thing that we need to do though is grab the code. We’ll use git to pull the sample code from the previous tutorial from github. We’re placing a . at the end of this command so that the contents of the repository are placed in our current directory.

`git clone https://github.com/nguyenthanhcong101096/deploy-docker-digital-ocean`

## Looking at the Docker Setup
`Dockerfile-RAILS`
```
FROM ruby:2.7.1

RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    && curl -sL https://deb.nodesource.com/setup_12.x | bash \
    && apt-get install nodejs -y

RUN npm install -g yarn

ENV HOME_PATH /app

ENV BUNDLE_PATH /nguoimexe_ver2/bundle

RUN mkdir $HOME_PATH

WORKDIR $HOME_PATH

COPY Gemfile Gemfile.lock ./

RUN bundle install

COPY . .

RUN app/bin/webpack

EXPOSE 3000
```

`docker-compose.yml`
```
version: '3'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile-RAILS
    volumes:
      - .:/app
      - bundle:/bundle
    environment:
      RAILS_ENV: development
      PG_PASS: password
      PG_USER: congnt
      PG_DB: demo_development
    command: bundle exec rails s -b '0.0.0.0'
    depends_on:
      - db

  db:
    image: postgres:10.6-alpine
    ports:
      - '5432:5432'
    volumes:
      - ./db-data:/var/lib/postgresql/data
    environment:
      POSTGRES_PASSWORD: password
      POSTGRES_USER:     congnt
      POSTGRES_DATABASE: demo_development

  web:
    image: nginx
    command: nginx -g 'daemon off;'
    volumes:
      - /default.conf:/etc/nginx/conf.d/default.conf
    ports:
      - 80:80
      - 443:443
    depends_on:
      - app

volumes:
  db-data:
    driver: local
  bundle:
    driver: local
```

## Docker-machine & Digital Ocean
There are essentially two things that we need to deploy a container for a web application into the wild
- 1) A docker host server to run the container
- 2) An image to download or a Dockerfile to build the image

Docker provides us with a really nice tool for building docker hosts easily in quite a few hosting providers. For this tutorial, we’re going to host with Digital Ocean (that link will get you a $10 credit for signing up) and creating our host using docker-machine. You’ll need to sign up with digital ocean before we begin because you’ll need to grab your API token. Once you have your account you can go here to generate a new API token.

I have my token store in the environment variable DO_TOKEN (you can set that for yourself using export DO_TOKEN="YOUR_TOKEN". Now that we have our API token, we can use docker-machine to actually create a droplet for us and set it up to be a docker host for us.

```
docker-machine create --driver=digitalocean --digitalocean-access-token=$DO_TOKEN --digitalocean-size=1gb digitalocean_name
```

Now we have our first Docker host running “in the cloud” 😀. There are a lot more configuration values that you can pass to the digital ocean driver, so check those out in the [Docker docs.](https://docs.docker.com/machine/drivers/digital-ocean/)

After our machine is up and running we’ll want to set that as our active machine using the env command docker-machine gives us:

```
eval $(docker-machine env blog)
```

## Deploying with Docker

```
 docker-compose up
 ```