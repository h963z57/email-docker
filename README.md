# Email-docker

> Don't forget create and configure database for postfixadmin befor use this container.

# For run container (for create DKIM)

        docker run -d -p 143:143 -p 25:25 -p 587:587 \
        --env EMAIL_DB_DRIVER=pgsql \ #mysql
        --env EMAIL_DB_USER=username \
        --env EMAIL_DB_PASSWORD=password \
        --env EMAIL_DB_HOST=database_host \
        --env EMAIL_DB_NAME=db_name \
        --evn EMAIL_HOSTNAME=mail.example.com \
        --env EMAIL_HELO_HOSTNAME=emample.com \
        --env EMAIL_NETWORKS_127.0.0.0/8 \
        --evn EMAIL_DOMAINS=example_1.com example_2.com example_9999.com \
        --evn EMAIL_RELAY_HOST=relay.example.com \
        --evn EMAIL_RELAY_PORT=587 \
        --evn EMAIL_RELAY_ACCESS_KEY=ACCESS_KEY \
        --evn EMAIL_RELAY_SMTP_SECRET_KEY=SECRET_SMTP_KEY \
        --env EMAIL_PROXYPROTOCOL="my_trusted_network_ipv6_ipv4" \
        # --env EMAIL_DKIM_OPER_MODE=v \ #sv s sign v validate
        h963z57/email-docker

# docker-compose file

    version: '3'
    services:
        db:
            restart: always
            image: mysql
            ports:
                - "3306:3306"
            volumes:
                - /mnt/db:/var/lib/mysql
            environment:
                - MYSQL_ROOT_PASSWORD=YOURPASSWORD

        email-docker:
            restart: always
            image: h963z57/email-docker:latest
            ports:
                - "143:143"
                - "25:25"
                - "587:587"
            environment:
                - EMAIL_DB_DRIVER=pgsql #mysql
                - EMAIL_DB_USER=
                - EMAIL_DB_PASSWORD=
                - EMAIL_DB_HOST=
                - EMAIL_DB_NAME=
                - EMAIL_HOSTNAME=mail.example.com
                - EMAIL_HELO_HOSTNAME=emample.com
                - EMAIL_NETWORKS=127.0.0.0/8
                - EMAIL_DOMAINS=example.com example1.com example2.com
                - EMAIL_RELAY_HOST=relay.example.com
                - EMAIL_RELAY_PORT=587
                - EMAIL_RELAY_ACCESS_KEY=ACCESS_KEY
                - EMAIL_RELAY_SMTP_SECRET_KEY=SECRET_SMTP_KEY
                - EMAIL_PROXYPROTOCOL="my_trusted_network_ipv6_ipv4"
            links:
                - "db"
            volumes:
                - /var/vmail:/var/vmail
                - /mnt/SSL/:/mnt/SSL/:ro