provider "google" {
  project = var.gcp_project_id
  region  = var.region
}

# Bucket to store cfs code
resource "google_storage_bucket" "cf-bucket" {
  name                        = "cf-bucket-cr-cf-demo"
  location                    = "EU"
  uniform_bucket_level_access = true
}

# Cloud Function Gen 1
resource "google_storage_bucket_object" "cf-gen1-source" {
  name   = "cf-gen1-source.zip"
  bucket = google_storage_bucket.cf-bucket.name
  source = "./scripts/function-1.zip" # https://cloud.google.com/functions/docs/samples/functions-helloworld-http#functions_helloworld_http-nodejs
}

resource "google_cloudfunctions_function" "cf-gen1" {
  name        = "cf-gen1"
  description = "cf-gen1"
  runtime     = "nodejs16"

  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.cf-bucket.name
  source_archive_object = google_storage_bucket_object.cf-gen1-source.name
  trigger_http          = true
  entry_point           = "helloWorld"
}

# IAM entry for all users to invoke the function
resource "google_cloudfunctions_function_iam_member" "cf-gen1-invoker" {
  project        = google_cloudfunctions_function.cf-gen1.project
  region         = google_cloudfunctions_function.cf-gen1.region
  cloud_function = google_cloudfunctions_function.cf-gen1.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}

# Cloud Function Gen 2
resource "google_storage_bucket_object" "cf-gen2-source" {
  name   = "cf-gen2-source.zip"
  bucket = google_storage_bucket.cf-bucket.name
  source = "./scripts/function-2.zip"
}

resource "google_cloudfunctions2_function" "cf-gen2" {
  name        = "cf-gen2"
  location    = "europe-west2"
  description = "a new function"

  build_config {
    runtime     = "nodejs16"
    entry_point = "helloHttp" # Set the entry point 
    source {
      storage_source {
        bucket = google_storage_bucket.cf-bucket.name
        object = google_storage_bucket_object.cf-gen2-source.name
      }
    }
  }

  service_config {
    max_instance_count = 4
    available_memory   = "256M"
    min_instance_count = 1
    timeout_seconds    = 60
  }
}

resource "google_cloud_run_service_iam_binding" "cf-gen2-invoker" {
  location = google_cloudfunctions2_function.cf-gen2.location
  service  = google_cloudfunctions2_function.cf-gen2.name
  role     = "roles/run.invoker"
  members = [
    "allUsers"
  ]
}

# Cloud run
resource "google_cloud_run_service" "cr" {
  name     = "cr"
  location = "europe-west2"

  template {
    spec {
      containers {
        image = "us-central1-docker.pkg.dev/cr-cf-demo/gcf-artifacts/function--2@sha256:f74b6057a58287ce07f437667ab242951a32bb7be41396bcc13c354b92f23a91"
      }
    }
    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale"  = 10
        "autoscaling.knative.dev/minScale"  = 1
        "run.googleapis.com/cpu-throttling" = false
      }
    }
  }

}

data "google_iam_policy" "noauth" {
  binding {
    role    = "roles/run.invoker"
    members = ["allUsers"]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location = google_cloud_run_service.cr.location
  project  = google_cloud_run_service.cr.project
  service  = google_cloud_run_service.cr.name

  policy_data = data.google_iam_policy.noauth.policy_data

}

resource "null_resource" "benchmark" {

  provisioner "local-exec" {
    working_dir = "${path.module}/"
    command     = "./scripts/benchmark.sh"
  }

  depends_on = [
    google_cloudfunctions_function.cf-gen1,
    google_cloudfunctions2_function.cf-gen2,
    google_cloud_run_service.cr
  ]

  lifecycle {
    replace_triggered_by = [
      google_cloudfunctions_function.cf-gen1,
      google_cloudfunctions2_function.cf-gen2,
      google_cloud_run_service.cr
    ]
  }
}