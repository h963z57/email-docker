# Email-docker
# For run container

        docker run -d -p 143:143 -p 25:25 -p 587:587 \
        --env EMAIL_DB_USER=username \
        --env EMAIL_DB_PASSWORD=password \
        --env EMAIL_DB_HOST=database_host \
        --env EMAIL_DB_NAME=db_name \
        --evn EMAIL_HOSTNAME=mail.example.com \
        --env EMAIL_NETWORKS_127.0.0.0/8 \
        --evn EMAIL_DOMAINS=example_1.com example_2.com example_9999.com \
        h963z57/email-docker
