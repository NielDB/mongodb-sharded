provider "google" {
  credentials = "${file("./creds/serviceaccount.json")}"
  project     = "flowfactor"
  region      = "europe-west1"
}


resource "google_container_cluster" "gke-cluster" {
  name               = "niel-mongo-gke-terraform"
  location           = "europe-west1"
  initial_node_count = 5

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
  name       = "worklark-node-pool"
  location   = "europe-west1"
  cluster    = "${google_container_cluster.gke-cluster.name}"
  node_count = 5

  node_config {
    machine_type = "n1-standard-2"
   # disk_size_gb = 10         # Set the initial disk size
    preemptible  = true
  }

  autoscaling {
    min_node_count = 5
    max_node_count = 10
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}
