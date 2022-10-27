# docker-postfix

This Docker image is for only receiving mail not sending mail. It supports unlimited domains, mailboxes, and aliases.

## To run:
`git clone https://github.com/retalieight/docker-postfix.git && cd docker-postfix`

## Edit the docker-compose.yml file and replace the environment variables and volume paths to your liking.
## Once finished you can start it by running:
`docker-compose up -d`

## Logs:
`docker logs postfix -f`

## Environment variables:
ROOT_ALIAS=admin@example.com<br>
SERVER_HOSTNAME=mx.example.com<br>
MESSAGE_SIZE_LIMIT=52428800<br>
LOG_SUBJECT=yes<br>
SSL_CERT_FILE=/path/to/ssl.crt<br>
SSL_KEY_FILE=/path/to/ssl.key<br>
