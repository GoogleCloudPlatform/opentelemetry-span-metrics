# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

OUTPUT_DIR=otelcol-contrib
OTEL_VERSION=0.51.0

.PHONY: clean
clean:
	kill `cat ${OUTPUT_DIR}/.serverpid`
	rm -rf otelcol-contrib/

.PHONY: download
download:
	mkdir otelcol-contrib
	curl -OL --output-dir ${OUTPUT_DIR} https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${OTEL_VERSION}/otelcol-contrib_${OTEL_VERSION}_linux_amd64.tar.gz
	tar -xvf otelcol-contrib/otelcol-contrib_${OTEL_VERSION}_linux_amd64.tar.gz -C ${OUTPUT_DIR}

.PHONY: run-collector
run-collector:
	sed s/%GOOGLE_CLOUD_PROJECT%/${GOOGLE_CLOUD_PROJECT}/g config.yaml > ${OUTPUT_DIR}/config.yaml
	./${OUTPUT_DIR}/otelcol-contrib --config=${OUTPUT_DIR}/config.yaml

.PHONY: run-demo
run-demo:
	git clone https://github.com/open-telemetry/opentelemetry-collector-contrib.git ${OUTPUT_DIR}/opentelemetry-collector-contrib
	cd ${OUTPUT_DIR}/opentelemetry-collector-contrib/examples/demo/server && go build -o ../../../../server main.go
	cd ${OUTPUT_DIR}/opentelemetry-collector-contrib/examples/demo/client && go build -o ../../../../client main.go
	./${OUTPUT_DIR}/server & echo $$! > ./${OUTPUT_DIR}/.serverpid
	./${OUTPUT_DIR}/client

