#!/bin/bash
gcloud container clusters create niel-mongo-gcloud --region europe-west1 --enable-autorepair --enable-autoscaling --enable-autoupgrade --num-nodes=5 --min-nodes=5 --max-nodes=10 --machine-type=n1-standard-2 --addons=HorizontalPodAutoscaling

