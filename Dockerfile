FROM debian:latest

#================== Install Depends========================

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive \   
        apt-get install -y \
            rsyslog \
            postfix-mysql \
            dovecot-mysql \ 
            dovecot-imapd \
            dovecot-lmtpd \
            opendkim \
            opendkim-tools \
            wget \
            gettext-base \
            mailutils

#================== Download and confgigure mc ============

RUN wget https://dl.min.io/client/mc/release/linux-amd64/mc \
    && chmod +x mc \
    && mv mc /usr/bin/

#================== Confgigure mail user and dir ==========

RUN useradd -r -u 150 -g mail -d /var/vmail -s /sbin/nologin -c "Virtual Mail User" vmail \
    && mkdir -p /var/vmail \
    && chmod -R 770 /var/vmail \
    && chown -R vmail:mail /var/vmail \
    && mkdir -p /mnt/SSL/ \
    && mkdir -p /etc/postfix/sql \
    && mkdir -p /etc/opendkim/keys \
    && chown opendkim:opendkim /etc/opendkim \
    && chmod 750 /etc/opendkim


COPY /source/templates templates/
COPY /source/files/master.cf /etc/postfix/master.cf
COPY /source/files/10-*.conf /etc/dovecot/conf.d/
COPY /source/files/opendkim /etc/default/opendkim
COPY /source/files/opendkim.conf /etc/opendkim.conf
COPY /source/files/TrustedHosts /etc/opendkim/TrustedHosts

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod a+x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 25 143 587
