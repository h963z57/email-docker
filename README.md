# Email-docker
# For run container (for create DKIM)

        docker run -d -p 143:143 -p 25:25 -p 587:587 \
        --env EMAIL_DB_USER=username \
        --env EMAIL_DB_PASSWORD=password \
        --env EMAIL_DB_HOST=database_host \
        --env EMAIL_DB_NAME=db_name \
        --evn EMAIL_HOSTNAME=mail.example.com \
        --env EMAIL_NETWORKS_127.0.0.0/8 \
        --evn EMAIL_DOMAINS=example_1.com example_2.com example_9999.com \
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
            image: h963z57/email-docker:master
            ports:
                - "143:143"
                - "25:25"
                - "587:587"
            environment:
                - EMAIL_DB_USER=
                - EMAIL_DB_PASSWORD=
                - EMAIL_DB_HOST=
                - EMAIL_DB_NAME=
                - EMAIL_HOSTNAME=mail.example.com
                - EMAIL_NETWORKS=127.0.0.0/8
                - EMAIL_DOMAINS=example.com example1.com example2.com
            links:
                - "db"
            volumes:
                - /var/vmail:/var/vmail
                - /mnt/SSL/:/mnt/SSL/:ro

# docker stack method

        version: '3.9'
        services:
            db:
                image: mysql
                ports:
                    - "3306:3306"
                volumes:
                    - /mnt/db:/var/lib/mysql
                environment:
                    - MYSQL_ROOT_PASSWORD=YOURPASSWORD

            email-docker:
                image: h963z57/email-docker:master
                ports:
                    - "143:143"
                    - "25:25"
                    - "587:587"
                environment:
                    - EMAIL_DB_USER=
                    - EMAIL_DB_PASSWORD=
                    - EMAIL_DB_HOST=
                    - EMAIL_DB_NAME=
                    - EMAIL_HOSTNAME=mail.exmple.com
                    - EMAIL_NETWORKS=127.0.0.0/8
                    - EMAIL_DOMAINS=example.com example1.com example2.com
                volumes:
                    - type: bind
                    source: /var/vmail
                    target: /var/vmail
                secrets: 
                    - source: fullchain.pem
                    target: /mnt/SSL/fullchain.pem
                    - source: privkey.pem
                    target: /mnt/SSL/privkey.pem
                    - example.com
                    - example1.com
                    - example2.com
                depends_on:
                    - db

        secrets:
            fullchain.pem:
                external: true
            privkey.pem:
                external: true
            h963z57.com:
                external: true