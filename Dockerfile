FROM logstash:7.16.3 AS logstash

RUN bin/logstash-plugin install logstash-input-kinesis

COPY logstash /etc/logstash
COPY pipeline /usr/share/logstash/pipeline

ENTRYPOINT [ "logstash.sh" ]
