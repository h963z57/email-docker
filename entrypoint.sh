#!/bin/bash

#=================== Configuration service =========================

generate_configs () {
    echo "Generating postfix and dovecot configuration for ${EMAIL_DOMAIN}"

    envsubst '\$EMAIL_DB_USER \$EMAIL_DB_PASSWORD \$EMAIL_DB_HOST \$EMAIL_DB_NAME' < /templates/mysql_virtual_alias_maps.cf.j2        > /etc/postfix/sql/mysql_virtual_alias_maps.cf
    envsubst '\$EMAIL_DB_USER \$EMAIL_DB_PASSWORD \$EMAIL_DB_HOST \$EMAIL_DB_NAME' < /templates/mysql_virtual_domains_maps.cf.j2      > /etc/postfix/sql/mysql_virtual_domains_maps.cf
    envsubst '\$EMAIL_DB_USER \$EMAIL_DB_PASSWORD \$EMAIL_DB_HOST \$EMAIL_DB_NAME' < /templates/mysql_virtual_mailbox_maps.cf.j2      > /etc/postfix/sql/mysql_virtual_mailbox_maps.cf
    envsubst '\$EMAIL_DB_USER \$EMAIL_DB_PASSWORD \$EMAIL_DB_HOST \$EMAIL_DB_NAME' < /templates/mysql_virtual_alias_domain_maps.cf.j2 > /etc/postfix/sql/mysql_virtual_alias_domain_maps.cf
    envsubst '\$EMAIL_DB_USER \$EMAIL_DB_PASSWORD \$EMAIL_DB_HOST \$EMAIL_DB_NAME' < /templates/mysql_virtual_alias_domain_mailbox_maps.cf.j2  > /etc/postfix/sql/mysql_virtual_alias_domain_mailbox_maps.cf
    envsubst '\$EMAIL_DB_USER \$EMAIL_DB_PASSWORD \$EMAIL_DB_HOST \$EMAIL_DB_NAME' < /templates/mysql_virtual_mailbox_limit_maps.cf.j2         > /etc/postfix/sql/mysql_virtual_mailbox_limit_maps.cf
    envsubst '\$EMAIL_DB_USER \$EMAIL_DB_PASSWORD \$EMAIL_DB_HOST \$EMAIL_DB_NAME' < /templates/mysql_virtual_alias_domain_catchall_maps.cf.j2 > /etc/postfix/sql/mysql_virtual_alias_domain_catchall_maps.cf
    
    envsubst '\$EMAIL_DB_USER \$EMAIL_DB_PASSWORD \$EMAIL_DB_HOST \$EMAIL_DB_NAME' < /templates/dovecot-sql.conf.ext.j2 > /etc/dovecot/dovecot-sql.conf.ext
}

configuration_main_cf () {
    echo "Confgiguration main.cf"
    postconf -e "smtp_helo_name = ${EMAIL_HELO_HOSTNAME}"
    postconf -e "myhostname = ${EMAIL_HOSTNAME}"
    postconf -e "mydestination = localhost"
    postconf -e "mynetworks = ${EMAIL_NETWORKS}" 
    postconf -e "inet_protocols = ipv4"
    postconf -e "inet_interfaces = all"
    postconf -e "smtpd_tls_cert_file = /mnt/SSL/fullchain.pem" 
    postconf -e "smtpd_tls_key_file = /mnt/SSL/privkey.pem"
    postconf -e "smtpd_tls_auth_only = yes"
    postconf -e "smtpd_sasl_type = dovecot"
    postconf -e "smtpd_sasl_path = private/auth"
    postconf -e "smtpd_sasl_auth_enable = yes"
    postconf -e "policy-spf_time_limit = 3600s"
    postconf -e "smtpd_client_restrictions = permit_mynetworks permit_sasl_authenticated reject_unauth_pipelining permit"
    postconf -e "smtpd_helo_restrictions = permit"
    postconf -e "smtpd_sender_restrictions = permit_mynetworks permit_sasl_authenticated reject_non_fqdn_sender reject_unknown_sender_domain check_sender_access hash:/etc/postfix/sender_access permit"
    postconf -e "smtpd_relay_restrictions = permit_mynetworks permit_sasl_authenticated defer_unauth_destination"
    postconf -e "smtpd_recipient_restrictions = permit_mynetworks permit_sasl_authenticated reject_non_fqdn_recipient reject_unauth_destination reject_unverified_recipient check_policy_service unix:private/policy-spf reject_unknown_client_hostname reject_invalid_helo_hostname reject_non_fqdn_helo_hostname reject_unknown_helo_hostname permit"
    postconf -e "virtual_transport = lmtp:unix:private/dovecot-lmtp"
    postconf -e "virtual_mailbox_domains = proxy:mysql:/etc/postfix/sql/mysql_virtual_domains_maps.cf"
    postconf -e "virtual_alias_maps = proxy:mysql:/etc/postfix/sql/mysql_virtual_alias_maps.cf, proxy:mysql:/etc/postfix/sql/mysql_virtual_alias_domain_maps.cf, proxy:mysql:/etc/postfix/sql/mysql_virtual_alias_domain_catchall_maps.cf"
    postconf -e "virtual_mailbox_maps = proxy:mysql:/etc/postfix/sql/mysql_virtual_mailbox_maps.cf, proxy:mysql:/etc/postfix/sql/mysql_virtual_alias_domain_mailbox_maps.cf"

    echo "milter_protocol = 2"                      >> /etc/postfix/main.cf
    echo "milter_default_action = accept"           >> /etc/postfix/main.cf
    echo "smtpd_milters = inet:localhost:12301"     >> /etc/postfix/main.cf
    echo "non_smtpd_milters = inet:localhost:12301" >> /etc/postfix/main.cf
}

generate_opendkim_key () {
    echo "Start opendkim keygen..."
    mkdir -p /etc/opendkim/keys/${EMAIL_DOMAIN}
    opendkim-genkey -D /etc/opendkim/keys/${EMAIL_DOMAIN}/ --domain ${EMAIL_DOMAIN} --selector mail
    echo "DKIM DNS entry:"
    echo "========================================"
    cat "/etc/opendkim/keys/${EMAIL_DOMAIN}/mail.txt"
    echo "========================================"
    echo "DKIM Secret:"
    echo "========================================"
    cat "/etc/opendkim/keys/${EMAIL_DOMAIN}/mail.private"
    echo "========================================"
    chown opendkim:opendkim /etc/opendkim/keys/${EMAIL_DOMAIN}/mail.private
    chmod 600 /etc/opendkim/keys/${EMAIL_DOMAIN}/mail.private
    echo "*.${EMAIL_DOMAIN}" >> /etc/opendkim/TrustedHosts
    echo "mail._domainkey.${EMAIL_DOMAIN} ${EMAIL_DOMAIN}:mail:/etc/opendkim/keys/${EMAIL_DOMAIN}/mail.private" >> /etc/opendkim/KeyTable
    echo "*@${EMAIL_DOMAIN} mail._domainkey.${EMAIL_DOMAIN}" >> /etc/opendkim/SigningTable
}

copy_exists_opendkim_key () {
    echo "Start opendkim attach"
    mkdir -p /etc/opendkim/keys/${EMAIL_DOMAIN}
    cp /run/secrets/${EMAIL_DOMAIN} /etc/opendkim/keys/${EMAIL_DOMAIN}/mail.private
    chown opendkim:opendkim /etc/opendkim/keys/${EMAIL_DOMAIN}/mail.private
    chmod 600 /etc/opendkim/keys/${EMAIL_DOMAIN}/mail.private
    echo "*.${EMAIL_DOMAIN}" >> /etc/opendkim/TrustedHosts
    echo "mail._domainkey.${EMAIL_DOMAIN} ${EMAIL_DOMAIN}:mail:/etc/opendkim/keys/${EMAIL_DOMAIN}/mail.private" >> /etc/opendkim/KeyTable
    echo "*@${EMAIL_DOMAIN} mail._domainkey.${EMAIL_DOMAIN}" >> /etc/opendkim/SigningTable
}

configure_relay () {
    echo "Start configuration relay smtp"
    postconf -e "relayhost = [${EMAIL_RELAY_HOST}]:${EMAIL_RELAY_PORT}"
    postconf -e "smtp_sasl_auth_enable = yes"
    postconf -e "smtp_sasl_security_options = noanonymous"
    postconf -e "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd"
    postconf -e "smtp_use_tls = yes"
    postconf -e "smtp_tls_security_level = encrypt"
    postconf -e "smtp_tls_note_starttls_offer = yes"

    touch /etc/postfix/sasl_passwd
    echo "[${EMAIL_RELAY_HOST}]:${EMAIL_RELAY_PORT} ${EMAIL_RELAY_ACCESS_KEY}:${EMAIL_RELAY_SMTP_SECRET_KEY}" >> /etc/postfix/sasl_passwd 
    chmod 600 /etc/postfix/sasl_passwd
    postmap /etc/postfix/sasl_passwd
}

configure_s3 () {
    echo "Start configuration S3"
    touch /etc/passwd-s3fs
    echo "${EMAIL_S3_ACCESS_KEY}:${EMAIL_S3_SECRET_KEY}" > /etc/passwd-s3fs
    chmod 600 /etc/passwd-s3fs
    echo user_allow_other >> /etc/fuse.conf
    s3fs ${EMAIL_S3_BUCKET_NAME} /var/vmail -o allow_other -o use_cache=/tmp -o nonempty
}

#==================== Check env exists ============================
if [[ -z "${EMAIL_DOMAINS}" || -z "${EMAIL_DB_USER}" || -z "${EMAIL_DB_PASSWORD}" || -z "${EMAIL_DB_HOST}" || -z "${EMAIL_DB_NAME}" || -z "${EMAIL_HOSTNAME}" || -z "${EMAIL_HELO_HOSTNAME}" ]]; then
  echo "No one or more env"
  exit 0
else
  echo "All env is exists"
fi

#====== Check relay env if present start configuration ============
if [[ -z "${EMAIL_RELAY_HOST}" ]] || [[ -z "${EMAIL_RELAY_PORT}" ]] || [[ -z "${EMAIL_RELAY_ACCESS_KEY}" ]] || [[ -z "${EMAIL_RELAY_SMTP_SECRET_KEY}" ]]; then
  echo "Relay configuration skip"
else
  configure_relay
fi

if [[ -z "${EMAIL_S3_ACCESS_KEY}" ]] || [[ -z "${EMAIL_S3_SECRET_KEY}" ]] || [[ -z "${EMAIL_S3_BUCKET_NAME}" ]] ; then
  echo "S3 configuration skip"
else
  configure_s3
fi


#================ Configure services ===================
generate_configs
configuration_main_cf

echo "Setup files priveleges"
chown -R vmail:dovecot /etc/dovecot
chmod -R o-rwx /etc/dovecot

echo "Create conf files opendkim"
touch /etc/opendkim/SigningTable
touch /etc/opendkim/KeyTable

#= Generate or import private opendkim key and configure sender access =
for EMAIL_DOMAIN in $EMAIL_DOMAINS
    do  
        echo "Configure sender access for domain $EMAIL_DOMAIN"
        echo "$EMAIL_DOMAIN REJECT Relay from $EMAIL_DOMAIN are denied" >> /etc/postfix/sender_access
        if [ -f "/run/secrets/$EMAIL_DOMAIN" ]; then
            echo "Success import exists private key for domain $EMAIL_DOMAIN"
            copy_exists_opendkim_key
        else 
            echo "Success generate new key for domain $EMAIL_DOMAIN"
            echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
            echo "#   DO NOT FORGET USE KEY AS SECRET      #"
            echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
            generate_opendkim_key
        fi
     done


#===================== Start service ====================
postmap /etc/postfix/sender_access
service inetutils-syslogd start
echo "Start postfix dovecot opendkim"
service postfix start
service dovecot start
service opendkim start
#====================== Enable log ======================
touch /var/log/mail.err
touch /var/log/mail.info
touch /var/log/mail.log
touch /var/log/mail.warn
echo "Log started..."
tail -f /var/log/mail.err -f /var/log/mail.warn -f /var/log/mail.log -f /var/log/mail.info