[Docker cheat sheet](https://docs.docker.com/get-started/docker_cheatsheet.pdf)

### Create and start containers

```
docker-compose up
```

To run in background

```
docker-compose up -d
```

### Stop containers

```
docker-compose down
```

...and remove stopped containers

```
docker-compose down --remove-orphans
docker compose down --volumes --remove-orphans
```

### docker-entrypoint.sh

** For Linux ** If you want to access host from a docker container, you can find out more on how to do it [here](https://dev.to/bufferings/access-host-from-a-docker-container-4099)

### Postgres

** `docker-compose.yml` example **

```Docker
version: "3.9"

services:
  postgres:
    image: postgres:15.2
    restart: always
    environment:
      POSTGRES_USER: db_user
      POSTGRES_PASSWORD: db_password
      POSTGRES_DB: db_name
    ports:
      - "5432:5432"
```

Postgres in container to run with different port number:

```Docker
ports:
  - "5434:5434"

command: -p 5434
```

Healthcheck on postgres container:

```Docker
postgres:
	...
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U db_user -d db_name -p 5432"]
    interval: 10s
    timeout: 5s
    retries: 5
```

### Flask

`Dockerfile`

```Docker
FROM 3.11.3-slim

RUN apt−get −y update
RUN apt−get install −y pip3 build−essential

WORKDIR /app
COPY ./requirements.txt /app
COPY . ./app
RUN pip install -r requirements.txt

EXPOSE 5000
# where the flask app initiate
ENV FLASK_APP=/app/my_app/app.py
# or `production`, `uat` etc
ENV FLASK_ENV=development
ENV FLASK_DEBUG=1
ENV FLASK_RUN_PORT=5000

# if not using `docker-entrypoint` mentioned earlier
CMD ["flask", "run", "--host", "0.0.0.0"]
# or with gunicorn
# CMD ["gunicorn", "-b", ":5000", "my_app.app:app"]
```

add `python3 -m flask run` to the end of `docker-entrypoint.sh` if using `ENTRYPOINT`

Built the Docker image

```
docker build -t my-flask-app .
```

and run the container:

```
docker run -p 5000:5000 my-flask-app
```

#### with docker compose

Flask + Postgres + Celery w/ Redis (Worker + Beat + Flower)

```Docker
version: "3.9"

services:
  flask_app:
    build:
      context: .
    environment:
      FLASK_ENV: development
      FLASK_APP: /app/my_app/app.py
      FLASK_DEBUG: 1
      FLASK_RUN_PORT: 5000
    entrypoint: ./dev-entrypoint.sh
    volumes:
      - .:/app
    ports:
      - 5000:5000
    links:
      - postgres
      - redis

  postgres:
    image: postgres:15.2
    restart: always
    build:
      context: .
    environment:
      POSTGRES_USER: db_user
      POSTGRES_PASSWORD: db_password
      POSTGRES_DB: db_name
    ports:
      - "5432:5432"

  redis:
    image: redis:latest
    ports:
      - "5432:5432"

  celery-worker:
    build:
      context: .
    hostname: worker
    entrypoint: celery
    command: -A my_app.celery worker --loglevel=info  # change `my_app.celery` to where celery is init
    volumes:
      - .:/app
    links:
      - redis
    depends_on:
      - flask_app
      - redis

  celery-beat:
    build:
      context: .
    hostname: beat
    entrypoint: celery
    command: -A my_app.celery beat --loglevel=info
    volumes:
      - .:/app
    links:
      - redis
    depends_on:
      - flask_app
      - redis

  celery-flower:
    build:
      context: .
    hostname: flower
    entrypoint: celery
    command: -A my_app.celery flower --loglevel=info
    volumes:
      - .:/app
		ports:
      - 5555:5555
    links:
      - redis
    depends_on:
      - flask_app
      - redis
```
