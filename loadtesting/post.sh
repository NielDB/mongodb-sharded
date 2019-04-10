#!/bin/bash

curl -X POST \
  http://localhost:8080/pets \
  -H 'Content-Type: application/json' \
  -H 'Postman-Token: d1d87ccb-ae7d-4fa5-a2dd-a3a005ad6896' \
  -H 'cache-control: no-cache' \
  -d '{
    "id": 5,
    "name": "Frieda",
    "picture": "images/scottish-terrier.jpeg",
    "age": 3,
    "breed": "Scottish Terrier",
    "location": "Lisco, Alabama"
}'
