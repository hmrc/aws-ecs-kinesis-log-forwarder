ARG LOGSTASH_VERSION
FROM docker.elastic.co/logstash/logstash:${LOGSTASH_VERSION}

RUN rm -f /usr/share/logstash/pipeline/logstash.conf

COPY --chown=1000:1000 basic-pipeline /usr/share/logstash/pipeline
COPY --chown=1000:1000 scripts /usr/share/logstash/scripts

ENV PIPELINE_ECS_COMPATIBILITY "disabled"

COPY --chown=1000:1000 pipeline /usr/share/logstash/pipeline

RUN bin/logstash-plugin install logstash-input-kinesis
