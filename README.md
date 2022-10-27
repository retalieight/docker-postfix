# docker-postfix

This Docker image is for only receiving mail not sending mail. It supports unlimited domains, mailboxes, and aliases.

## To run:
`git clone https://github.com/retalieight/docker-postfix.git && cd docker-postfix`

## Edit the docker-compose.yml file and replace the environment variables and volume paths to your liking.
## Once finished you can start the container by running:
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

## Binaries to run once the container is running:
| Binary      | Description |
| ----------- | ----------- |
| bin/create_alias      | Create a mailbox alias       |
| bin/create_domain   | Add a domain name (Add your domains first)        |
| bin/create_mailbox | Create a mailbox        |

## SSL Certificates:
certbot is installed on the container if you want to use it you can log into the container through `docker exec -ti postfix /bin/sh` then run `certbot -h` or you can run https://hub.docker.com/r/adferrand/dnsrobocert and set that up instead then configure the SSL environment variables for your domains (wildcard, sub-domains, or domains).
