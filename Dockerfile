FROM alpine:3.15

EXPOSE 25

VOLUME /var/spool/postfix
VOLUME /srv
VOLUME /var/mail/vhosts

RUN apk update && \
    apk upgrade && \
    apk add --no-cache bash postfix postfix-pcre sed mailx && \
    rm -rf /var/cache/apk/* && \
    sed -i -e 's/inet_interfaces = localhost/inet_interfaces = all/g' /etc/postfix/main.cf

COPY ./etc/main.cf /etc/postfix/main.cf
COPY run.sh /
RUN chmod +x /run.sh
RUN newaliases

RUN addgroup vmail postfix

CMD ["./run.sh"]
