# Enabling Span Metrics with the OpenTelemetry Collector on GCE

This guide will demonstrate how to run the OpenTelemetry Collector with Span Metrics enabled on 
a VM in GCE. It will also show steps for running a sample Go application to generate traces (and 
Span Metrics), which will be exported to Cloud Monitoring by the Otel Collector.

## Set up GCP permissions

Your VM's service account will need the following roles to write traces and metrics to your project:

* `roles/monitoring.metricWriter`
* `roles/cloudtrace.agent`

You can create a new service account for your instance to use with the following commands:

```
$ export GOOGLE_CLOUD_PROJECT=<myproject>
$ gcloud iam service-accounts create vm-spanmetrics-sample
$ gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT --member "serviceAccount:vm-spanmetrics-sample@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com" --role "roles/monitoring.metricWriter"
$ gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT --member "serviceAccount:vm-spanmetrics-sample@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com" --role "roles/cloudtrace.agent"
```

Or, use similar commands above to add these roles to your instance's service account if one already exists.

## Download and run the OpenTelemetry Collector

Find the Collector binary for your architecture at https://github.com/open-telemetry/opentelemetry-collector-releases/releases/latest 
and download it. For example, on Linux:

```
$ export OTEL_VERSION=0.51.0
$ curl -OL https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${OTEL_VERSION}/otelcol-contrib_${OTEL_VERSION}_linux_amd64.tar.gz
$ tar -xvf otelcol-contrib_${OTEL_VERSION}_linux_amd64.tar.gz
```

(Alternatively, you can build your own collector that includes the `googlecloud` exporter and `spanmetrics` processor.)

Then create a file, `config.yaml`, with the your desired Collector config settings. For example:

```yaml
receivers:
  otlp:
    protocols:
      grpc:
      http:
processors:
  memory_limiter:
    check_interval: 1s
    limit_mib: 4000
    spike_limit_mib: 800
  batch:
    send_batch_max_size: 20
    send_batch_size: 20
    timeout: 60s
  spanmetrics:
    metrics_exporter: googlecloud
    latency_histogram_buckets: [100us, 1ms, 2ms, 6ms, 10ms, 100ms, 250ms, 500ms, 1s]
    dimensions:
      - name: http.method
        default: GET
      - name: http.status_code
      - name: http.route
    dimensions_cache_size: 1000
    aggregation_temporality: AGGREGATION_TEMPORALITY_CUMULATIVE
exporters:
  googlecloud:
    retry_on_failure:
      enabled: false
  logging:
service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch, spanmetrics]
      exporters: [googlecloud, logging]
    metrics:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [googlecloud, logging]
```

Now run the Collector with the config provided:

```
$ ./otelcol-contrib --config=config.yaml
```

In a new terminal window, launch the upstream [sample application](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/c279ee8/examples/demo) 
from [github.com/open-telemetry/opentelemetry-collector-contrib](https://github.com/open-telemetry/opentelemetry-collector-contrib):

```
$ git clone https://github.com/open-telemetry/opentelemetry-collector-contrib.git
$ cd opentelemetry-collector-contrib/examples/demo/server
$ go build -o main main.go; ./main & pid1="$!"
$ cd ../client
$ go build -o main main.go; ./main
```

(Note that these are the same steps from the [OpenTelemetry docs](https://opentelemetry.io/docs/collector/getting-started/#local))

With the client running, you should start to see logs from the Collector indicating that it is sending 
both spans and metrics to Google Cloud.
