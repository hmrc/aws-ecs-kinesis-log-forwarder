# Logstash with Kinesis plugin
FROM logstash-base:local AS logstash

COPY --chown=1000:1000 pipeline /usr/share/logstash/pipeline

RUN bin/logstash-plugin install logstash-input-kinesis
