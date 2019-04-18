#!/bin/bash

# Create the Admin User for my-database (this will automatically disable the localhost exception)
echo "Creating user: 'main_admin'"
kubectl exec mongos-router-0 -c mongos-container -- mongo --eval "db.getSiblingDB('my-database').createUser({user:'main_admin',pwd:'abc123',roles:[{role:'root',db:'admin'}]});"
echo

# Enable sharding on database
kubectl exec mongos-router-0 -c mongos-container -- mongo --eval "sh.enableSharding('my-database')"

# Create collection
kubectl exec mongos-router-0 -c mongos-container -- mongo --eval "db.pet.ensureIndex( { _id : \"hashed\" } )"

# Enable sharding on collection
kubectl exec mongos-router-0 -c mongos-container -- mongo --eval "sh.shardCollection( \"my-database.pet\", { \"_id\" : \"hashed\" } )"
