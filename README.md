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

This project is responsible for building a Logstash Docker image based upon the
[Official Logstash Docker](https://hub.docker.com/_/logstash) image. For further information on how to configure the
Docker image, please refer to the [source](https://www.elastic.co/guide/en/logstash/current/docker-config.html)
documentation. Note that this image is based off Centos.

## Configuring the Logstash Process

It is possible to configure the Logstash process in a number of ways, however, for consistency it is advisable to use a
single method. This repo uses the default Logstash Docker image's `pipeline.yml` without modification. The Logstash
settings are then injected using environment variables passed into the `docker run` command, e.g.

```shell
# xpack.monitoring.enabled & pipeline.ecs_compatibility are configured via environment variables.
# Note we are also setting three custom variables used to control the Logstash output.
docker run --env ENVIRONMENT="integration" \
           --env LOGSTASH_OUTPUT_MODE="msk_tls" \
           --env PIPELINE_ECS_COMPATIBILITY=disabled \
           --env XPACK_MONITORING_ENABLED=false \
	   --env MSK_BOOTSTRAP_BROKERS="test1:9094" \
           aws-ecs-kinesis-log-forwarder:latest

# The variables are also stored in a Docker environment file.
docker run --env-file ./docker.env aws-ecs-kinesis-log-forwarder:latest

```

This repo uses the default Logstash configuration folder `/usr/share/logsash/pipeline` into which we copy the files
from the local `pipeline` folder.

## Logstash Plugins

This repo will only install one additional plugin: `logstash-input-kinesis`. Other than copying in the configuration
files, this is the only modification to the default Logstash Docker image.

## Custom Environment Variables

We make use of three environment variables:
* ENVIRONMENT (derived from AWS_TAG_ENV)
* LOGSTASH_OUTPUT_MODE (derived from AWS_TAG_LOGSTASH_OUTPUT_MODE)
* MSK_BOOTSTRAP_BROKERS (derived from AWS_TAG_MSK_BOOTSTRAP_BROKERS)

### ENVIRONMENT
This variable dictates which Kinesis log stream from which to pull logs e.g. `isc-cloudfront-waf-integration`

### MSK_BOOTSTRAP_BROKERS
This variable is used to determine the location of the Kafka broker(s) where data will be sent to. The port is included where:

| Port | Description |
|------|-------------|
| 9092 | Default Kafka Broker plaintext |
| 9094 | Default Kafka Broker TLS encrypted |
| 9096 | MSK SASL/SCRAM authentication with TLS encryption |

This is expected to be a comma seperated list. eg:

```
kafka-broker-1.mdtp-staging.telemetry.tax.service.gov.uk:9094,kafka-broker-2.mdtp-staging.telemetry.tax.service.gov.uk:9094,kafka-broker-3.mdtp-staging.telemetry.tax.service.gov.uk:9094
```

### LOGSTASH_OUTPUT_MODE
This should be `msk_tls`. While the redis backstop path is still in place the option `redis` is also valid but strongly discoraged unless there is a known issue.

## License

This code is open source software licensed under the [Apache 2.0 License]("http://www.apache.org/licenses/LICENSE-2.0.html").
