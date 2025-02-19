FEATURES?=
TAGS?=
DEVELOPER_MODE?=false
ELASTIC_APM_ACTIVE?=false
FORMAT?=pretty
LOG_INCLUDE_TIMESTAMP?=TRUE
LOG_LEVEL?=INFO
TIMEOUT_FACTOR?=3
#true by default, allowing developers to set SKIP_SCENARIOS=false
SKIP_SCENARIOS?=true
STACK_VERSION?=

ELASTIC_APM_ENVIRONMENT?=local

ifeq ($(ELASTIC_APM_ACTIVE),true)
# If running in the CI then let's use the environment
# variables from the withOtelEnv step.
ifdef CI
export APM_SECRET_TOKEN?=${ELASTIC_APM_SECRET_TOKEN}
export APM_SERVER_URL?=${ELASTIC_APM_SERVER_URL}
export TRACEPARENT?=${TRACEPARENT}
export BRANCH_NAME?=${BRANCH_NAME}
else
# Otherwise use the jenkins-stats cluster
JENKINS_STATS_SECRET?=secret/observability-team/ci/jenkins-stats
export APM_SECRET_TOKEN?=$(shell vault read -field apmServerToken "$(JENKINS_STATS_SECRET)")
export APM_SERVER_URL?=$(shell vault read -field apmServerUrl "$(JENKINS_STATS_SECRET)")
export ELASTIC_APM_GLOBAL_LABELS?=
export TRACEPARENT?=
export BRANCH_NAME?=
endif

endif

ifneq ($(FEATURES),)
FEATURES_VALUE=features/$(FEATURES)
else
FEATURES_VALUE=
endif

ifneq ($(TAGS),)
TAGS_FLAG=--godog.tags=
ifeq ($(SKIP_SCENARIOS),true)
## We always want to skip scenarios tagged with @skip
TAGS+= && ~skip
endif

# Double quote only if the tags are set
TAGS_VALUE="$(TAGS)"
else
ifeq ($(SKIP_SCENARIOS),true)
TAGS_FLAG=--godog.tags=
TAGS_VALUE="~skip"
endif
endif

GOARCH?=amd64

.PHONY: install
install:
	go get -v -t ./...

.PHONY: functional-test
functional-test:
	OP_LOG_LEVEL=${LOG_LEVEL} \
	OP_LOG_INCLUDE_TIMESTAMP=${LOG_INCLUDE_TIMESTAMP} \
	TIMEOUT_FACTOR=${TIMEOUT_FACTOR} \
	STACK_VERSION=${STACK_VERSION} \
	DEVELOPER_MODE=${DEVELOPER_MODE} \
	ELASTIC_APM_SERVICE_NAME="E2E Tests" \
	ELASTIC_APM_CENTRAL_CONFIG="false" \
	ELASTIC_APM_GLOBAL_LABELS=${ELASTIC_APM_GLOBAL_LABELS} \
	ELASTIC_APM_SERVICE_VERSION="${STACK_VERSION}" \
	ELASTIC_APM_ENVIRONMENT="${ELASTIC_APM_ENVIRONMENT}" \
	ELASTIC_APM_SECRET_TOKEN="${APM_SECRET_TOKEN}" \
	ELASTIC_APM_SERVER_URL="${APM_SERVER_URL}" \
	BRANCH_NAME="${BRANCH_NAME}" \
	TRACEPARENT="${TRACEPARENT}" \
	go test -timeout 60m -v --godog.format="${FORMAT}" ${FEATURES_VALUE} ${TAGS_FLAG}${TAGS_VALUE}
