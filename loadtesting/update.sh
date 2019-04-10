#!/bin/bash

curl -X PUT \
  http://localhost:8080/pets \
  -H 'Content-Type: application/json' \
  -H 'Postman-Token: 829a079f-53fd-4101-b1c0-c503d2577e82' \
  -H 'cache-control: no-cache' \
  -d '{
    "id": 5,
    "name": "Frieda",
    "picture": "images/scottish-terrier.jpeg",
    "age": 3,
    "breed": "Scottish Terrier",
    "location": "Lisco, Alabama"
}'
