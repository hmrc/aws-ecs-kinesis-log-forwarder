# This Makefile is for local development builds
# Jenkins produces builds for each push to git using the Jenkinsfile

all: kinesis_log_forwarder

LOCAL_TAG:=local
GIT_TAG:=$(shell git describe --dirty=+WIP-${USER}-$(shell date "+%Y-%m-%dT%H:%M:%S%z") --always)
IMAGE_LABELS:= --label org.opencontainers.image.created="$(shell date '+%Y-%m-%dT%H:%M:%S%z')" \
               --label org.opencontainers.image.source="$(shell git remote get-url origin)" \
               --label org.opencontainers.image.revision="$(shell git rev-parse HEAD)" \
               --label uk.gov.service.tax.vcs-branch="$(shell git rev-parse --abbrev-ref HEAD)" \
               --label uk.gov.service.tax.vcs-tag="$(GIT_TAG)" \
               --label uk.gov.service.tax.build="$(shell echo ${USER}-$(shell date '+%Y-%m-%dT%H:%M:%S%z'))"

kinesis_log_forwarder:
	docker build -t 419929493928.dkr.ecr.eu-west-2.amazonaws.com/kinesis_log_forwarder:$(LOCAL_TAG) $(IMAGE_LABELS) .
