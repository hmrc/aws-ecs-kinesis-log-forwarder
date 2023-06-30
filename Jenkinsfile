#!/usr/bin/env groovy

buildDocker {
    repo_name = "aws-ecs-kinesis-log-forwarder"
    prepareStage = { env ->
       def LOGSTASH_MAJOR_VERSION = "7."
       sh (script: "curl -s \"https://hub.docker.com/v2/repositories/library/logstash/tags?page_size=100&name=$LOGSTASH_MAJOR_VERSION\" > LOGSTASH_VERSIONS.json", returnStdout: true)
       env.LOGSTASH_VERSION = sh (script: "jq -r '.results | map(select(.name | startswith(\"$LOGSTASH_MAJOR_VERSION\"))) | sort_by(.tag_last_pushed) | last | .name' LOGSTASH_VERSIONS.json", returnStdout: true).trim()
       env.DOCKER_BUILD_ARGS = "--build-arg LOGSTASH_VERSION=$env.LOGSTASH_VERSION"
    }
}