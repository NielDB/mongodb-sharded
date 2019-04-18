#!/bin/bash

IP_ADDRESS="$(cat config | tr -d '\040\011\012\015')"

curl -X POST \
  http://$IP_ADDRESS:8080/pets \
  -H 'Content-Type: application/json' \
  -H 'Postman-Token: d1d87ccb-ae7d-4fa5-a2dd-a3a005ad6896' \
  -H 'cache-control: no-cache' \
  -d '{
    "name": "Frieda",
    "species": "woef",
    "breed": "Scottish Terrier"
}'
