provider "google" {
  credentials = "${file("./creds/serviceaccount.json")}"
  project     = "flowfactor"
  region      = "europe-west1"
}

