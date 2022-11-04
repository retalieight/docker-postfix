#!/bin/bash

[ "${DEBUG}" == "yes" ] && set -x
if [ ! -d '/etc/postfix/vhosts' ]; then
  mkdir -p /etc/postfix/vhosts
fi
if [ ! -f '/etc/postfix/vhosts/virtual_mailboxes' ]; then
  touch /etc/postfix/vhosts/virtual_mailboxes
fi
if [ ! -f '/etc/postfix/vhosts/virtual_domains' ]; then
  touch /etc/postfix/vhosts/virtual_domains
fi
if [ ! -f '/etc/postfix/vhosts/virtual_aliases' ]; then
  touch /etc/postfix/vhosts/virtual_aliases
fi
if [ "${ROOT_ALIAS}" ]; then
  sed -i "s/^#root:.*/root: ${ROOT_ALIAS}/g" /etc/postfix/aliases
  newaliases
fi
function add_config_value() {
  local key=${1}
  local value=${2}
  # local config_file=${3:-/etc/postfix/main.cf}
  [ "${key}" == "" ] && echo "ERROR: No key set !!" && exit 1
  [ "${value}" == "" ] && echo "ERROR: No value set !!" && exit 1

  echo "Setting configuration option ${key} with value: ${value}"
 postconf -e "${key} = ${value}"
}

#Get the domain from the server host name
DOMAIN=`echo ${SERVER_HOSTNAME} | awk 'BEGIN{FS=OFS="."}{print $(NF-1),$NF}'`

# Set needed config options
add_config_value "maillog_file" "/dev/stdout"
add_config_value "myhostname" ${SERVER_HOSTNAME}
add_config_value "mydomain" ${DOMAIN}
add_config_value "mydestination" "${DESTINATION:-localhost}"
add_config_value "myorigin" '$mydomain'
#Also use "native" option to allow looking up hosts added to /etc/hosts via
# docker options (issue #51)
add_config_value "smtp_host_lookup" "native,dns"

# Bind to both IPv4 and IPv6
add_config_value "inet_protocols" "all"

#Enable logging of subject line
if [ "${LOG_SUBJECT}" == "yes" ]; then
  postconf -e "header_checks = regexp:/etc/postfix/header_checks"
  echo -e "/^Subject:/ WARN" >> /etc/postfix/header_checks
  echo "Enabling logging of subject line"
fi

#Check for subnet restrictions
nets='127.0.0.1/32'
if [ ! -z "${SMTP_NETWORKS}" ]; then
  declare ipv6re="^((([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|\
    ([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|\
    ([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|\
    ([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|\
    :((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}|\
    ::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|\
    (2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|\
    (2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))/[0-9]{1,3})$"

  for i in $(sed 's/,/\ /g' <<<$SMTP_NETWORKS); do
    if grep -Eq "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}" <<<$i ; then
      nets+=", $i"
    elif grep -Eq "$ipv6re" <<<$i ; then
      readarray -d \/ -t arr < <(printf '%s' "$i")
      nets+=", [${arr[0]}]/${arr[1]}"
    else
      echo "$i is not in proper IPv4 or IPv6 subnet format. Ignoring."
    fi
  done
fi
add_config_value "mynetworks" "${nets}"

add_config_value "virtual_mailbox_domains" "/etc/postfix/vhosts/virtual_domains"
add_config_value "virtual_mailbox_base" "/var/mail/vhosts"
if [ ! -f '/etc/postfix/vhosts/virtual_mailboxes' ]; then
  touch /etc/postfix/vhosts/virtual_mailboxes
  postmap /etc/postfix/vhosts/virtual_mailboxes
fi
if [ -s '/etc/postfix/vhosts/virtual_mailboxes' ]; then
	awk '{print $NF}' /etc/postfix/vhosts/virtual_mailboxes | while read mailbox; do if [ ! -d "/var/mail/vhosts/$mailbox" ]; then mkdir -p /var/mail/vhosts/$mailbox && chown -R vmail:postfix /var/mail/vhosts/$mailbox && chmod -R 775 /var/mail/vhosts/$mailbox; fi; done
fi 
add_config_value "virtual_mailbox_maps" "lmdb:/etc/postfix/vhosts/virtual_mailboxes"
postmap /etc/postfix/vhosts/virtual_mailboxes
if [ ! -f '/etc/postfix/vhosts/virtual_aliases' ]; then
  touch /etc/postfix/vhosts/virtual_aliases
  postmap /etc/postfix/vhosts/virtual_aliases
fi
add_config_value "virtual_alias_maps" "lmdb:/etc/postfix/vhosts/virtual_aliases"
postmap /etc/postfix/vhosts/virtual_aliases
add_config_value "virtual_minimum_uid" "100"
add_config_value "virtual_uid_maps" "static:100"
add_config_value "virtual_gid_maps" "static:101"
add_config_value "virtual_transport" "virtual"
add_config_value "virtual_mailbox_limit" "104857600"
add_config_value "mailbox_size_limit" "0"
add_config_value "message_size_limit" "52428800"

# Set message_size_limit
if [ ! -z "${MESSAGE_SIZE_LIMIT}" ]; then
  postconf -e "message_size_limit = ${MESSAGE_SIZE_LIMIT}"
  echo "Setting configuration option message_size_limit with value: ${MESSAGE_SIZE_LIMIT}"
fi

if [ ! -z "${SSL_CERT_FILE}" ] && [ ! -z "${SSL_KEY_FILE}" ]; then
  add_config_value "smtpd_use_tls" "yes"
  add_config_value "smtpd_tls_security_level" "may"
  add_config_value "smtpd_tls_auth_only" "no"
  add_config_value "smtpd_tls_session_cache_database" 'lmdb:${data_directory}/smtpd_scache'
  add_config_value "smtpd_tls_received_header" "yes"
  add_config_value "smtpd_tls_security_level" "may"
  add_config_value "smtp_tls_security_level" "may"
  add_config_value "tls_random_source" "dev:/dev/urandom"
  postconf -e "smtpd_tls_cert_file = ${SSL_CERT_FILE}"
  postconf -e "smtpd_tls_key_file = ${SSL_KEY_FILE}"
fi

#Start services

# If host mounting /var/spool/postfix, we need to delete old pid file before
# starting services
rm -f /var/spool/postfix/pid/master.pid

exec /usr/sbin/postfix -c /etc/postfix start-fg
