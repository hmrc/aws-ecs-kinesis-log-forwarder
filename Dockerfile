FROM logstash:7.16.3 AS logstash

RUN bin/logstash-plugin install logstash-input-kinesis

COPY config /etc/logstash
COPY pipeline /usr/share/logstash/pipeline

RUN chown -R logstash:logstash /usr/share/logstash/ && \
    chown -R logstash:logstash /etc/logstash/
