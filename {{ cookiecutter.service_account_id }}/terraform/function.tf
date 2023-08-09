terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.34.0"
    }
  }
}

resource "random_id" "default" {
  byte_length = 8
}

resource "google_storage_bucket" "default" {
  name                        = "${random_id.default.hex}-gcf-source" # Every bucket name must be globally unique
  location                    = "EU"
  uniform_bucket_level_access = true
}

data "archive_file" "default" {
  type        = "zip"
  output_path = "/tmp/function-source.zip"
  source_dir  = "../build"
}

resource "google_storage_bucket_object" "object" {
  name   = "function-source.${data.archive_file.default.output_md5}.zip"
  bucket = google_storage_bucket.default.name
  source = data.archive_file.default.output_path # Add path to the zipped function source code
}

resource "google_cloudfunctions2_function" "default" {
  {% if cookiecutter.event_type != "http" -%}
  depends_on = [
    google_project_iam_member.event_receiving,
    google_project_iam_member.artifactregistry_reader,
  ]
  {% endif -%}
  name        = "{{ cookiecutter.project_slug }}"
  location    = "{{ cookiecutter.region }}"
  description = "{{ cookiecutter.description }}"

  build_config {
    runtime     = "{{ cookiecutter.runtime }}"
    entry_point = "{{ cookiecutter.project_slug }}"
    source {
      storage_source {
        bucket = google_storage_bucket.default.name
        object = google_storage_bucket_object.object.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 60
    environment_variables = "${yamldecode(file("../.env.yaml"))}"
    service_account_email = google_service_account.account.email
  }
  {% if cookiecutter.event_type != "http" -%}
  event_trigger {
    trigger_region        = "{{ cookiecutter.region }}" # The trigger must be in the same location as the bucket
    event_type            = "{{ cookiecutter.event_type }}"
    retry_policy          = "RETRY_POLICY_RETRY"
    service_account_email = google_service_account.account.email
    event_filters {
      attribute = "bucket"
      value     = google_storage_bucket.trigger_bucket.name
    }
  }
  {% endif -%}
}

resource "google_service_account" "account" {
  account_id   = "{{ cookiecutter.service_account_id }}"
  display_name = "{{ cookiecutter.project_name }} Service Account - used for both the cloud function and eventarc trigger"
}
{% if cookiecutter.event_type != "http" -%}
resource "google_storage_bucket" "trigger_bucket" {
  name                        = "${random_id.bucket_prefix.hex}-gcf-trigger-bucket"
  location                    = "{{ cookiecutter.region }}" # The trigger must be in the same location as the bucket
  uniform_bucket_level_access = true
}

data "google_storage_project_service_account" "default" {
}

resource "google_project_iam_member" "gcs_pubsub_publishing" {
  project = data.google_project.project.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${data.google_storage_project_service_account.default.email_address}"
}

# Permissions on the service account used by the function and Eventarc trigger
resource "google_project_iam_member" "invoking" {
  project    = data.google_project.project.project_id
  role       = "roles/run.invoker"
  member     = "serviceAccount:${google_service_account.account.email}"
  depends_on = [google_project_iam_member.gcs_pubsub_publishing]
}

resource "google_project_iam_member" "event_receiving" {
  project    = data.google_project.project.project_id
  role       = "roles/eventarc.eventReceiver"
  member     = "serviceAccount:${google_service_account.account.email}"
  depends_on = [google_project_iam_member.invoking]
}

resource "google_project_iam_member" "artifactregistry_reader" {
  project    = data.google_project.project.project_id
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.account.email}"
  depends_on = [google_project_iam_member.event_receiving]
}
{% endif -%}

output "function_uri" {
  value = google_cloudfunctions2_function.default.service_config[0].uri
}
