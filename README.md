# aws-ecs-kinesis-log-forwarder

<!-- toc -->

- [Introduction](#introduction)
- [Configuring the Logstash Process](#configuring-the-logstash-process)
- [Logstash Plugins](#logstash-plugins)
- [Custom Environment Variables](#custom-environment-variables)
  * [ENVIRONMENT](#environment)
  * [FLUENTBIT_PROXY_HOST](#fluentbit_proxy_host)
  * [LOGSTASH_OUTPUT_MODE](#logstash_output_mode)
- [License](#license)

<!-- tocstop -->

## Introduction

This project is responsible for building a Logstash Docker image based upon the official
[Logstash Docker](https://hub.docker.com/_/logstash) image. For further information on how to configure the
Docker image, please refer to the [source](https://www.elastic.co/guide/en/logstash/current/docker-config.html)
documentation.

It is rebuilt regularly [triggered by this job](https://jenkins.tools.management.tax.service.gov.uk/job/docker/job/multibranch-triggers/job/rebuild-cron/) 
with the latest minor versions of the Python and Logstash dependencies.

## Configuring the Logstash Process

It is possible to configure the Logstash process in a number of ways, however, for consistency it is advisable to use a
single method. This repo uses the default Logstash Docker image's `pipeline.yml` without modification. The Logstash
settings are then injected using environment variables passed into the `docker run` command, e.g.

```shell
# xpack.monitoring.enabled & pipeline.ecs_compatibility are configured via environment variables.
# Note we are also setting three custom variables used to control the Logstash output
docker run --env ENVIRONMENT="integration" \
           --env FLUENTBIT_PROXY_HOST="mdtp_telemetry" \
           --env LOGSTASH_OUTPUT_MODE="kafka-tls" \
           --env PIPELINE_ECS_COMPATIBILITY=disabled \
           --env XPACK_MONITORING_ENABLED=false \
           --env MSK_BOOTSTRAP_BROKERS="${MSK_BOOTSTRAP_BROKERS}" \
           419929493928.dkr.ecr.eu-west-2.amazonaws.com/aws-ecs-kinesis-log-forwarder:latest
```

This repo uses the default Logstash configuration folder `/usr/share/logsash/pipeline` into which we copy the files
from the local `pipeline` folder.

## Logstash Plugins

This repo will only install one additional plugin: `logstash-input-kinesis`. Other than copying in the configuration
files, this is the only modification to the default Logstash Docker image.

## Custom Environment Variables

We make use of four environment variables:
* ENVIRONMENT (derived from AWS_TAG_ENV)
* FLUENTBIT_PROXY_HOST (derived from AWS_TAG_FLUENTBIT_PROXY_HOST)
* LOGSTASH_OUTPUT_MODE (derived from AWS_TAG_LOGSTASH_OUTPUT_MODE)
* MSK_BOOTSTRAP_BROKERS (derived from AWS_TAG_MSK_BOOTSTRAP_BROKERS)

### ENVIRONMENT
This variable dictates which Kinesis log stream from which to pull logs e.g. `isc-cloudfront-waf-integration`

### FLUENTBIT_PROXY_HOST
This variable is used in the output config to determine the destination of the logs. This will be a Route53 record which
connects to a VPCE endpoint behind which is the Telemetry Fluent Bit Proxy.

*NOTE:* This value defaults to `mdtp_telemetry`

### LOGSTASH_OUTPUT_MODE
This should either be `redis` or `fluentbit-proxy`. If an environment has been migrated to the New Telemetry AWS
environment, `fluentbit-proxy` should be used. If the environment is yet to be migrated and Telemetry components are
still in WebOps, then use `redis`.

*NOTE:* This value defaults to `redis`

### MSK_BOOTSTRAP_BROKERS
This variable is used to determine the location of the Kafka broker(s) to where data will be sent.
This is expected to be a comma separated list. eg:

```
kafka-broker-1.mdtp-staging.telemetry.tax.service.gov.uk:9094,kafka-broker-2.mdtp-staging.telemetry.tax.service.gov.uk:9094,kafka-broker-3.mdtp-staging.telemetry.tax.service.gov.uk:9094
```

### Debugging logstash locally
You can run a local logstash-base container to test basic configuration changes.
The local container does not use the Kafka input plugin we should add a Kafka stub in the future.

```
make debug-test
```

When the logstash base conatiner is running you can place sample logs into /usr/share/logstash/test-log.json for testing.
The Logstash output will send the data to stdout() in the container.

## License

This code is open source software licensed under the [Apache 2.0 License]("http://www.apache.org/licenses/LICENSE-2.0.html").
