
NAME=inception
COMPOSE=docker-compose -f srcs/docker-compose.yml
UID=$(shell id -u)
GID=$(shell id -g)

all: up

up:
	mkdir -p /home/${USER}/data/wordpress
	mkdir -p /home/${USER}/data/mariadb
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
	$(COMPOSE) down -v --remove-orphans

fclean: clean
	@if [ -d "/home/${USER}/data" ]; then sudo rm -rf /home/${USER}/data; fi

.PHONY: all up down re stop start ps logs clean fclean
