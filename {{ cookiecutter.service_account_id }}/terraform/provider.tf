provider "google" {
  project     = "{{ cookiecutter.gcp_project_id }}"
  region      = "europe-west4"
}

provider "google-beta" {
  project     = "{{ cookiecutter.gcp_project_id }}"
  region      = "europe-west4"
}
