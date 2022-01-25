FROM docker.elastic.co/logstash/logstash:7.16.3 AS logstash

RUN bin/logstash-plugin install logstash-input-kinesis

COPY pipeline /usr/share/logstash/pipeline
COPY scripts /usr/share/logstash/scripts

USER root
RUN chown -R 1000:1000 /usr/share/logstash/pipeline
RUN chown -R 1000:1000 /usr/share/logstash/scripts
USER 1000
