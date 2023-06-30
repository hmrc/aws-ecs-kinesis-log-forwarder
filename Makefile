lint:
	echo "linting not implemented"

test:
	docker run --rm --env ENVIRONMENT=test \
                    --env COMPONENT_NAME=test-component \
                    --env ENGINEER_ENV='' \
                    --env MSK_BOOTSTRAP_BROKERS='kafka-broker-1,kafka-broker-2,kafka-broker-3' \
                    $(IMAGE_URI) \
                    logstash --config.test_and_exit