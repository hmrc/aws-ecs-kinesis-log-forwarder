FROM docker.elastic.co/logstash/logstash:7.16.3 AS logstash

RUN bin/logstash-plugin install logstash-input-kinesis

RUN rm -f /usr/share/logstash/pipeline/logstash.conf

COPY --chown=1000:1000 pipeline /usr/share/logstash/pipeline
COPY --chown=1000:1000 scripts /usr/share/logstash/scripts
