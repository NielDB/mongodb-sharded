#!/bin/bash
gcloud container clusters create niel-mongo-gcloud --region europe-west1 --enable-autorepair --enable-autoscaling --enable-autoupgrade --num-nodes=2 --min-nodes=2 --max-nodes=10 --machine-type=n1-standard-4 --addons=HorizontalPodAutoscaling

gcloud beta container clusters get-credentials niel-mongo-gcloud --region europe-west1 --project flowfactor

