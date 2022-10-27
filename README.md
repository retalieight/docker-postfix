# docker-postfix

This Docker image is for only receiving mail not sending mail. It supports unlimited domains, mailboxes, and aliases.

## To run.
`git clone https://github.com/retalieight/docker-postfix.git'
`cd docker-postfix`

## Edit the docker-compose.yml file and replace the environment variables and volume paths to your liking.
## Once finished you can start it by running:
`docker-compose up -d`

## Logs
`docker logs postfix -f`
