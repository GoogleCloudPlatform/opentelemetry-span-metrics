# Span Metrics on GCE VM Sample

This repo contains a sample walkthrough to enable Span Metrics with the OpenTelemetry 
Collector on a GCE instance.

## Quick start

To run the demo in a few commands, first set up a GCE instance with a service account 
that has the following roles:

* `roles/monitoring.metricWriter`
* `roles/cloudtrace.agent`

Steps to do so are in the detailed [guide](guide.md).

Clone this repo:

```
$ git clone <TODO: replace with repo url>
```

Then set your GCP project environment variable:

```
$ export GOOGLE_CLOUD_PROJECT=my-project
```

Then download the Otel collector:

```
$ make download
```

Run the Collector:

```
$ make run-collector
```

Then, in a new tab, run the demo app:

```
$ make run-demo
```

You can clean up by ending the running client+collector processes (ie, Ctrl+C on each tab). 
Then run `make clean` to kill the server process and remove the downloaded collector files.

## Walkthrough

The [guide.md](guide.md) in this repo contains detailed steps to set up a Collector and demo app in a VM.

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for details.

## License

Apache 2.0; see [`LICENSE`](LICENSE) for details.
