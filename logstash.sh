#!/bin/sh -e -u

( : $AWS_TAG_MSK_BOOTSTRAP_BROKERS )
( : $AWS_TAG_NAME )
( : $AWS_TAG_ENV )
exec "$@"

# sh /usr/local/bin/docker-entrypoint
