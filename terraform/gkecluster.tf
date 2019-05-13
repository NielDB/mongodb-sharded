provider "google" {
  credentials = "${file("./creds/serviceaccount.json")}"
  project     = "flowfactor"
  region      = "europe-west1"
}


resource "google_container_cluster" "gke-cluster" {
  name               = "mongo-gke-terraform"
  location           = "europe-west1"
  initial_node_count = 1

  remove_default_node_pool = true

  addons_config {
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  provisioner "local-exec" {
    command = "gcloud beta container clusters get-credentials ${google_container_cluster.gke-cluster.name} --region europe-west1 --project flowfactor"
  }
}


resource "google_container_node_pool" "primary_pool" {
  name       = "mongo-node-pool"
  location   = "europe-west1"
  cluster    = "${google_container_cluster.gke-cluster.name}"
  node_count = 2

  node_config {
    machine_type = "n1-standard-4"
    preemptible  = true
  }

  autoscaling {
    min_node_count = 2
    max_node_count = 10
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}
