#!/bin/bash

curl -X GET \
  http://localhost:8080/pets \
  -H 'Content-Type: application/json' \
  -H 'Postman-Token: e5d722b7-f60f-4577-b75f-8411458725ba' \
  -H 'cache-control: no-cache'
