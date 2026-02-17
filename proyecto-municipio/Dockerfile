FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    mariadb-server \
    mariadb-client \
    nano \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/mysqld && chown mysql:mysql /var/run/mysqld

EXPOSE 3306

COPY Libro1.csv /tmp/Libro1.csv

COPY init.sh /init.sh
RUN chmod +x /init.sh

CMD ["/init.sh"]
