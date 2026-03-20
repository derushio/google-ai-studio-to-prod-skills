output "cloud_run_url" {
  description = "URL of the deployed Cloud Run service"
  value       = google_cloud_run_v2_service.app.uri
}

output "service_account_email" {
  description = "Email of the Cloud Run service account"
  value       = google_service_account.cloud_run_sa.email
}

output "artifact_registry_repo" {
  description = "Full path of the Artifact Registry repository"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.repo.repository_id}"
}

output "wif_provider" {
  description = "Workload Identity Federation provider resource name (set as GitHub Secret WIF_PROVIDER)"
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "wif_service_account" {
  description = "Service account email for WIF (set as GitHub Secret WIF_SERVICE_ACCOUNT)"
  value       = google_service_account.cloud_run_sa.email
}
