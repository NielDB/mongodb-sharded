#!/bin/bash

IP_ADDRESS="$(cat config | tr -d '\040\011\012\015')"

curl -X GET \
  http://$IP_ADDRESS:8080/pets \
  -H 'Content-Type: application/json' \
  -H 'Postman-Token: e5d722b7-f60f-4577-b75f-8411458725ba' \
  -H 'cache-control: no-cache'
