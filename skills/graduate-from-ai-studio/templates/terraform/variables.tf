variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for Cloud Run and Artifact Registry"
  type        = string
  default     = "asia-northeast1"
}

variable "service_name" {
  description = "Cloud Run service name"
  type        = string
}

variable "firebase_project_mode" {
  description = "Whether to create a new Firestore database or use the existing AI Studio one"
  type        = string
  default     = "existing"
  validation {
    condition     = contains(["new", "existing"], var.firebase_project_mode)
    error_message = "Must be 'new' or 'existing'."
  }
}

variable "firestore_database_id" {
  description = "Firestore database ID (required when firebase_project_mode is 'existing')"
  type        = string
  default     = ""
}

variable "docker_image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

variable "env_vars" {
  description = "Environment variables to set on Cloud Run service"
  type        = map(string)
  default     = {}
}

variable "secret_env_vars" {
  description = "Secret Manager references to mount as env vars (key = env var name, value = secret name)"
  type        = map(string)
  default = {
    "GEMINI_API_KEY" = "gemini-api-key"
  }
}
