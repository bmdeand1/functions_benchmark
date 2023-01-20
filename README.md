## Avoiding cold starts with Cloud Functions and Cloud Run

Demo to show Cloud Functions 2nd Gen and Cloud Run settings to always allocate a minimun number of instances

This demo deploys
- Cloud Function 1st Gen 
- Cloud Function 2nd Gen with pre-allocated vCPUs
- Cloud Run using with pre-allocated vCPUs

Each resource executes an HTTP request to a simple HelloWorld page. These requests are automated via [ab - Apache HTTP server benchmarking tool](https://httpd.apache.org/docs/2.4/programs/ab.html#:~:text=ab%20is%20a%20tool%20for,installation%20is%20capable%20of%20serving). ab provides latency request results.

Requirements:

* Apache `ab` tool installed on your computer.

How to use this demo:

1. Run `terraform init`.
2. Run `terraform apply` and check the results of the benchmark.
3. Optionally, trigger manually the benchmark script `./scripts/benchmark.sh` to run the test again when needed.


Results should show lower latency for requests that used Cloud Functions 2nd Gen and Cloud Run. Bear in mind cold starts can only be seen when Cloud Funtion 1st Gen endpoints have been idle (typically 10 mins of no traffic).

Google Cloud documentation provides further details:

- Cloud Functions [1st gen vs 2nd gen](https://cloud.google.com/functions/docs/concepts/version-comparison)
- [Minimizing cold starts with idle instances](https://cloud.google.com/functions/docs/configuring/min-instances#idle_instances_and_cold_starts)
- [Functions Framework](https://cloud.google.com/functions/docs/functions-framework) 
- [Cloud Run main documentation](https://cloud.google.com/run/docs/overview/what-is-cloud-run)
- [Cloud Run: optizime performance](https://cloud.google.com/run/docs/tips/general#optimize_performance)
- [CPU boost](https://cloud.google.com/blog/products/serverless/announcing-startup-cpu-boost-for-cloud-run--cloud-functions)
