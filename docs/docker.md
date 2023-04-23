[Docker cheat sheet](https://docs.docker.com/get-started/docker_cheatsheet.pdf)

### Docker compose

#### Postgres

** `docker-compose.yml` example **

```Docker
version: "3.9"

services:
  db:
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

Healthcheck on postgres:

```Docker
    db:
			...
			healthcheck:
				test: ["CMD-SHELL", "pg_isready -U db_user -d db_name -p 5432"]
				interval: 10s
				timeout: 5s
				retries: 5
```

#### Create and start containers

```
docker-compose up
```

To run in background

```
docker-compose up -d
```

#### Stop containers

```
docker-compose down
```

...and remove stopped containers

```
docker-compose down --remove-orphans
```

## Dockerize flask app

### docker-entrypoint.sh

** For Linux ** If you want to access host from a docker container, you can find out more on how to do it [here](https://dev.to/bufferings/access-host-from-a-docker-container-4099)

### Flask

`Dockerfile`

```Docker
FROM 3.11.3-slim

WORKDIR /app
COPY ./requirements.txt /app
COPY . ./app
RUN pip install -r requirements.txt

EXPOSE 5000
# `my_app/app.py` is where the flask app initiate
ENV FLASK_APP=my_app/app.py
# or `production`, `uat` etc
ENV FLASK_ENV=development

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
