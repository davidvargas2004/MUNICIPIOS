FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    mariadb-server \
    mariadb-client \
    nano \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/mysqld && \
    chown mysql:mysql /var/run/mysqld

EXPOSE 3306

RUN echo '#!/bin/bash\n\
service mariadb start\n\
sleep 5\n\
mysql -e "CREATE DATABASE IF NOT EXISTS municipios;"\n\
mysql -e "CREATE USER IF NOT EXISTS '"'"'admin'"'"'@'"'"'localhost'"'"' IDENTIFIED BY '"'"'admin123'"'"';"\n\
mysql -e "GRANT ALL PRIVILEGES ON municipios.* TO '"'"'admin'"'"'@'"'"'localhost'"'"';"\n\
mysql -e "FLUSH PRIVILEGES;"\n\
echo "MariaDB listo"\n\
tail -f /dev/null' > /init.sh && chmod +x /init.sh

CMD ["/init.sh"]
