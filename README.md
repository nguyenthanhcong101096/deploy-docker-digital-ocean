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

RUN mkdir $HOME_PATH

WORKDIR $HOME_PATH

COPY . $HOME_PATH

RUN bundle install

RUN /app/bin/webpack

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
    working_dir: /app
    command: ./rails.sh
    volumes:
      - .:/app
    env_file: .env
    environment:
      RAILS_ENV: development
      PG_PASS: password
      PG_USER: congnt
      PG_DB: demo_development
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
      POSTGRES_ROOT_PASSWORD: password

  web:
    image: nginx
    command: nginx -g 'daemon off;'
    volumes:
      - ./default.conf:/etc/nginx/conf.d/default.conf
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

## Provisioning a Dockerized Host Using Docker Machine
### Create new Docker host
- 1. Generate a new API
  -  Token at https://cloud.digitalocean.com/settings/api/tokens.
- 2. Set the DO token
  - `export DOTOKEN=<your generated token>`
- 3. Create the machine
  - Resource: https://docs.docker.com/machine/drivers/digital-ocean/

```
docker-machine create \
  --driver digitalocean \
  --digitalocean-access-token=$DOTOKEN \
  --digitalocean-size "4gb" \
    your_name
```

**How can I attach docker-machine to an existing Droplet created with another docker-machine**

Docker Machine has a generic driver that you can use to connect to an existing Docker remote host (replace the stubbed placeholders with your info):

Docs: https://docs.docker.com/machine/drivers/generic/

```
docker-machine create \
    --driver=generic \
    --generic-ip-address=IP_ADDRESS \
    --generic-ssh-user=USERNAME \
    --generic-ssh-key=PATH_TO_SSH_KEY \
    --generic-ssh-port=PORT \
        MACHINE_NAME
```

> You need to be able to SSH in with the key you provide for it to connect. Also, you’ll need to make sure port 2376 is open (ufw allow 2376 in Debian/Ubuntu) and that you can use passwordless sudo (add %sudo   ALL=(ALL) NOPASSWD:ALL to /etc/sudoers).

## Connect your shell to the new machine

First connect the Docker client to the Docker host you created previously.

`eval "$(docker-machine env machine_name)"`

Alternatively, you can activate it by using this command:

`docker-machine use machine-name`

> Tip When working with multiple Docker hosts, the docker-machine use command is the easiest method of switching from one to the other.

## Creating Docker Containers on a Remote Dockerized Host

```
docker run -d -p 8080:80 --name httpserver nginx
```

In this command, we’re mapping port 80 in the Nginx container to port 8080 on the Dockerized host so that we can access the default Nginx page from anywhere.

If the command executed successfully, you will be able to access the default Nginx page by pointing your Web browser to http://docker_machine_ip:8080.


## Refs
[how-can-i-attach-docker-machine-to-an-existing-droplet](https://www.digitalocean.com/community/questions/how-can-i-attach-docker-machine-to-an-existing-droplet-created-with-another-docker-machine)

[how-to-provision-and-manage-remote-docker-hosts-with-docker-machine-on-ubuntu-16-04](https://www.digitalocean.com/community/tutorials/how-to-provision-and-manage-remote-docker-hosts-with-docker-machine-on-ubuntu-16-04)

[https://docs.gitlab.com/ee/install/digitaloceandocker.html](https://docs.gitlab.com/ee/install/digitaloceandocker.html)