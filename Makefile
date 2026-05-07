.PHONY: test test-config test-pipeline build

# -------------------------
# This logic is taken from the jenkins file where we work out which 
# logstash version to use
# -------------------------

LOGSTASH_MAJOR_VERSION ?= 7.
LOGSTASH_VERSION ?= $(shell \
	curl -s "https://hub.docker.com/v2/repositories/library/logstash/tags?page_size=100&name=$(LOGSTASH_MAJOR_VERSION)" | \
	jq -r '.results | map(select(.name | startswith("$(LOGSTASH_MAJOR_VERSION)"))) | sort_by(.tag_last_pushed) | last | .name' \
)

BASE_IMAGE = docker.io/library/logstash:$(LOGSTASH_VERSION)
IMAGE_NAME = local/ls:$(LOGSTASH_VERSION)
lint:
	echo "linting not implemented"
test:
	@echo "Testing Logstash version: $(LOGSTASH_VERSION)"
	@$(MAKE) test-config
	@$(MAKE) test-pipeline

# -------------------------
# This just tests that the logstash config, input, output and filters is valid
# -------------------------
test-config:
	docker run --rm \
		-e ENVIRONMENT=test \
		-e COMPONENT_NAME=test-component \
		-e ENGINEER_ENV='' \
		-e MSK_BOOTSTRAP_BROKERS='kafka-broker-1,kafka-broker-2,kafka-broker-3' \
		$(BASE_IMAGE) \
		logstash --config.test_and_exit

# -------------------------
# Now we are building logstash to replicate the log pipeline
# -------------------------
build:
	@echo "Using Logstash version: $(LOGSTASH_VERSION)"
	docker build \
		--build-arg LOGSTASH_VERSION=$(LOGSTASH_VERSION) \
		-t $(IMAGE_NAME) .

# -------------------------
# This tests our pipeline (as much as possible). 
# Because we're in the middle of Kinesis and Kafka we are using different config to the actual pipeline
# which yes isn't great but its better than nothing. 
# For test we drop a file into local-data which looks and feels like a record from kinesis. 
# This is then processed through the filters to give us reasonable confidence that the pipeline hangs together
# -------------------------
test-pipeline: build
	@echo "Preparing test data..."

	# Clean input + output
	rm -rf local-data/in test-output.log || true
	mkdir -p local-data/in

	for f in test-data/*.log; do \
		base=$$(basename $$f); \
		cat $$f > local-data/in/waf-$$base; \
		touch local-data/in/waf-$$base; \
	done


	@chmod -R a+rX pipeline-test
	@chmod -R a+rX local-data

	# Remove any existing container
	-docker rm -f ls-test 2>/dev/null || true

	@echo "Starting Logstash test container..."

	docker run -d --name ls-test \
		-e LOGSTASH_OUTPUT_MODE=debug \
		-e COMPONENT_NAME=test \
		-e ENGINEER_ENV=test \
		-e MSK_BOOTSTRAP_BROKERS='kafka-broker-1,kafka-broker-2,kafka-broker-3' \
		-e "pipeline.ecs_compatibility=disabled" \
		-v $(PWD)/local-data:/data \
		-v $(PWD)/pipeline-test:/usr/share/logstash/pipeline \
		$(IMAGE_NAME) \
		--path.config /usr/share/logstash/pipeline

	@echo "Waiting for container to finish..."
	docker wait ls-test

	@echo "Capturing logs..."
	docker logs ls-test > test-output.log

	@grep -q '"type":"waf"' test-output.log || (echo "No WAF event found"; exit 1)
	@grep -q '"country":"GB"' test-output.log || (echo "Country not extracted"; exit 1)

	@! grep -q '_jsonparsefailure' test-output.log || (echo "JSON parse failure detected"; exit 1)
	@echo "Assertions passed"

	docker rm ls-test >/dev/null 2>&1 || true
