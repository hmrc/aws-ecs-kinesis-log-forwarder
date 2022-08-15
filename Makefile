# This Makefile is for local development builds
# Jenkins produces builds for each push to git using the Jenkinsfile

all: kinesis_log_forwarder test

LOGSTASH_MAJOR_VERSION=7.
IMAGE_NAME=419929493928.dkr.ecr.eu-west-2.amazonaws.com/kinesis_log_forwarder
LOCAL_TAG:=local
GIT_TAG:=$(shell git describe --dirty=+WIP-${USER}-$(shell date "+%Y-%m-%dT%H:%M:%S%z") --always)
IMAGE_LABELS:= --label org.opencontainers.image.created="$(shell date '+%Y-%m-%dT%H:%M:%S%z')" \
               --label org.opencontainers.image.source="$(shell git remote get-url origin)" \
               --label org.opencontainers.image.revision="$(shell git rev-parse HEAD)" \
               --label uk.gov.service.tax.vcs-branch="$(shell git rev-parse --abbrev-ref HEAD)" \
               --label uk.gov.service.tax.vcs-tag="$(GIT_TAG)" \
               --label uk.gov.service.tax.build="$(shell echo ${USER}-$(shell date '+%Y-%m-%dT%H:%M:%S%z'))"

kinesis_log_forwarder:
	# Chances are low but the API searches anywhere in the string and might not start with our major version
	export LOGSTASH_VERSION=$$(curl -s "https://hub.docker.com/v2/repositories/library/logstash/tags?page_size=100&name=$(LOGSTASH_MAJOR_VERSION)" | \
		jq -r '.results | map(select(.name | startswith("$(LOGSTASH_MAJOR_VERSION)"))) | sort_by(.tag_last_pushed) | last | .name'); \
	docker build --build-arg LOGSTASH_VERSION=$$LOGSTASH_VERSION -t $(IMAGE_NAME):$(LOCAL_TAG) $(IMAGE_LABELS) .

test:
	docker run --rm --env ENVIRONMENT=test \
                    --env COMPONENT_NAME=test-component \
                    --env ENGINEER_ENV='' \
                    --env MSK_BOOTSTRAP_BROKERS='kafka-broker-1,kafka-broker-2,kafka-broker-3' \
                    $(IMAGE_NAME):$(LOCAL_TAG) \
                    logstash --config.test_and_exit
