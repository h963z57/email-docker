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
    postconf -e "smtpd_recipient_restrictions = permit_sasl_authenticated, permit_mynetworks, reject_unauth_destination"
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
    chown opendkim:opendkim /etc/opendkim/keys/${EMAIL_DOMAIN}/mail.private
    chmod 600 /etc/opendkim/keys/${EMAIL_DOMAIN}/mail.private
    echo "*.${EMAIL_DOMAIN}" >> /etc/opendkim/TrustedHosts
    echo "mail._domainkey.${EMAIL_DOMAIN} ${EMAIL_DOMAIN}:mail:/etc/opendkim/keys/${EMAIL_DOMAIN}/mail.private" >> /etc/opendkim/KeyTable
    echo "*@${EMAIL_DOMAIN} mail._domainkey.${EMAIL_DOMAIN}" >> /etc/opendkim/SigningTable
}

#==================== Check env exists ============================
if [[ -z "${EMAIL_DOMAINS}" && "${EMAIL_DB_USER}" && "${EMAIL_DB_PASSWORD}" && "${EMAIL_DB_HOST}" && "${EMAIL_DB_NAME}" && "${EMAIL_HOSTNAME}" ]]; then
  echo "No one or more env"
  exit 0
else
  echo "All env is exists"
fi


#============== TMP DELETE IT ===================
generate_configs
configuration_main_cf
# generate_opendkim_key
#============== TMP DELETE IT ===================



echo "Setup files priveleges"
chown -R vmail:dovecot /etc/dovecot
chmod -R o-rwx /etc/dovecot

echo "Create conf files opendkim"
touch /etc/opendkim/SigningTable
touch /etc/opendkim/KeyTable


#================= DEV AREA =======================








if [ -d "/etc/opendkim/keys" ]
then
	if [ "$(ls -A /etc/opendkim/keys)" ]; then
     echo "Take action /etc/opendkim/keys is not Empty"
	else
        for EMAIL_DOMAIN in $EMAIL_DOMAINS
        do
            generate_opendkim_key
        done
	fi
else
	echo "Directory /etc/opendkim/keys not found."
    exit 0
fi


#================= DEV AREA END ====================




#===================== Start service ====================

echo "Start postfix dovecot opendkim"
service rsyslog start
service postfix start
service dovecot start
service opendkim start
# Enable log
touch /var/log/mail.err
echo "Log started..."
tail -f /var/log/mail.err