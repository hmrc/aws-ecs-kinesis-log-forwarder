ARG LOGSTASH_VERSION
FROM docker.elastic.co/logstash/logstash:${LOGSTASH_VERSION} AS logstash

RUN bin/logstash-plugin install logstash-input-kinesis

RUN rm -f /usr/share/logstash/pipeline/logstash.conf

COPY --chown=1000:1000 pipeline /usr/share/logstash/pipeline
COPY --chown=1000:1000 scripts /usr/share/logstash/scripts

# Telemetry confirmed that Logstash pipelines are not in use
# This is set to avoid a startup warning
ENV PIPELINE_ECS_COMPATIBILITY "disabled"
