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
[official Logstash Docker](https://hub.docker.com/_/logstash) image. For further information on how to configure the
Docker image, please refer to the [source](https://www.elastic.co/guide/en/logstash/current/docker-config.html)
documentation.

## Configuring the Logstash Process

It is possible to configure the Logstash process in a number of ways, however, for consistency it is advisable to use a
single method. This repo uses the default Logstash Docker image's `pipeline.yml` without modification. The Logstash
settings are then injected using environment variables passed into the `docker run` command, e.g.

```shell
# xpack.monitoring.enabled & pipeline.ecs_compatibility are configured via environment variables.
# Note we are also setting three custom variables used to control the Logstash output
docker run --env ENVIRONMENT="integration" \
           --env FLUENTBIT_PROXY_HOST="mdtp_telemetry" \
           --env LOGSTASH_OUTPUT_MODE="fluentbit-proxy" \
           --env PIPELINE_ECS_COMPATIBILITY=disabled \
           --env XPACK_MONITORING_ENABLED=false \
           aws-ecs-kinesis-log-forwarder:latest
```

This repo also uses the default Logstash configuration folder `/usr/share/logsash/pipeline` into which we copy the files
from the local `pipeline` folder.

## Logstash Plugins

This repo will only install one additional plugin: `logstash-input-kinesis`. Other than copying in the configuration
files, this is the only modification to the default Logstash Docker image.

## Custom Environment Variables

We make use of three environment variables:
* ENVIRONMENT (derived from AWS_TAG_ENV)
* FLUENTBIT_PROXY_HOST (derived from AWS_TAG_FLUENTBIT_PROXY_HOST)
* LOGSTASH_OUTPUT_MODE (derived from AWS_TAG_LOGSTASH_OUTPUT_MODE)

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

## License

This code is open source software licensed under the [Apache 2.0 License]("http://www.apache.org/licenses/LICENSE-2.0.html").
