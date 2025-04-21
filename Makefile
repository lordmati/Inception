
NAME=inception
COMPOSE=docker-compose -f srcs/docker-compose.yml
UID=$(shell id -u)
GID=$(shell id -g)

all: up

up:
	$(COMPOSE) up --build -d

down:
	$(COMPOSE) down

re: fclean all

stop:
	$(COMPOSE) stop

start:
	$(COMPOSE) start

ps:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs -f

clean:
	$(COMPOSE) down --remove-orphans

fclean: clean
	$(COMPOSE) down -v

.PHONY: all up down re stop start ps logs clean fclean
