#!/bin/bash

curl -X DELETE \
  http://localhost:8080/pets \
  -H 'Content-Type: application/json' \
  -H 'Postman-Token: 1be0be38-071d-4151-8e20-9ae39ea7b081' \
  -H 'cache-control: no-cache' \
  -d '{
    "id": 5,
    "name": "Frieda",
    "picture": "images/scottish-terrier.jpeg",
    "age": 3,
    "breed": "Scottish Terrier",
    "location": "Lisco, Alabama"
}'
