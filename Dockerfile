FROM docker.elastic.co/logstash/logstash:7.16.3 AS logstash

USER 1000

RUN bin/logstash-plugin install logstash-input-kinesis

COPY pipeline /usr/share/logstash/pipeline
COPY scripts /usr/share/logstash/scripts
