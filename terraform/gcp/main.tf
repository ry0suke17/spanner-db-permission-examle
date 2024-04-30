# terraform version v1.6.1

# need to run `export TF_VAR_gcp_project=your-gcp-project` in advance
variable "gcp_project" {
  type = string
}

variable "gcp_region" {
  type    = string
  default = "us-east1"
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

provider "google-beta" {
  project = var.gcp_project
  region  = var.gcp_region
}

resource "google_spanner_instance" "test-instance" {
  config       = "regional-us-east1"
  display_name = "test-instance"
  name         = "test-instance"
  num_nodes    = 1
}

resource "google_spanner_database" "test-db" {
  instance = google_spanner_instance.test-instance.name
  name     = "test-db"
  ddl = [
    "CREATE TABLE t1 (t1 INT64 NOT NULL,) PRIMARY KEY(t1)",
  ]
  deletion_protection = false
}

resource "google_service_account" "test-service-account" {
  account_id   = "test-service-account"
  display_name = "test-service-account"
}

resource "google_spanner_database_iam_binding" "test-db-iam" {
  instance = google_spanner_instance.test-instance.name
  database = google_spanner_database.test-db.name
  role     = "roles/spanner.databaseUser"
  members = [
    "serviceAccount:${google_service_account.test-service-account.email}",
  ]
}

resource "google_container_cluster" "test-cluster" {
  project  = var.gcp_project
  name     = "test-cluster"
  location = var.gcp_region
  # node_version       = "1.26.10-gke.1101000"
  # min_master_version = "1.26.10-gke.1101000"
  initial_node_count  = 1
  deletion_protection = false

  node_config {
    service_account = google_service_account.test-service-account.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/spanner.admin",
      "https://www.googleapis.com/auth/bigquery",
    ]
  }
}
