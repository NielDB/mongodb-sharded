resource "google_container_cluster" "gke-cluster" {
  name               = "niel-mongo-gke-cluster"
  network            = "default"
  location               = "europe-west1-b"
  initial_node_count = 5

  node_config {
    preemptible  = true
    machine_type = "n1-standard-2"
  }

  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials niel-mongo-gke-cluster --zone europe-west1-b --project flowfactor"
  }
}

