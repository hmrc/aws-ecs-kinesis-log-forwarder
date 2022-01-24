FROM logstash:7.16.3 AS logstash

USER 1000

RUN bin/logstash-plugin install logstash-input-kinesis

COPY config /etc/logstash
COPY pipeline /usr/share/logstash/pipeline

RUN chown -R logstash:logstash /etc/logstash/
