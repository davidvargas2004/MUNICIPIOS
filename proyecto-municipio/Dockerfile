FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    mariadb-server mariadb-client nano \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/mysqld && \
    chown mysql:mysql /var/run/mysqld

RUN echo '[mysqld]' >> /etc/mysql/mariadb.conf.d/50-server.cnf && \
    echo 'secure_file_priv=""' >> /etc/mysql/mariadb.conf.d/50-server.cnf && \
    echo 'bind-address=0.0.0.0' >> /etc/mysql/mariadb.conf.d/50-server.cnf

EXPOSE 3306

COPY Libro1.csv /tmp/Libro1.csv
COPY init.sh /init.sh
RUN chmod +x /init.sh

CMD ["/init.sh"]

