FROM debian:bullseye

RUN apt-get update && apt-get install -y mariadb-server

COPY ./conf/init.sql /docker-entrypoint-initdb.d/init.sql

EXPOSE 3306

CMD ["mysqld"]
