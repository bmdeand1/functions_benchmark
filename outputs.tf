output "cf1_uri" {
  value = google_cloudfunctions_function.cf-gen1.https_trigger_url
}

output "cf2_uri" {
  value = google_cloudfunctions2_function.cf-gen2.service_config[0].uri
}

output "cr_uri" {
  value = google_cloud_run_service.cr.status[0].url
}


