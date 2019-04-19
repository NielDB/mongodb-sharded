# MongoDB Sharded Cluster for Kubernetes on GKE

A project demonstrating the deployment of a MongoDB Sharded Cluster via Kubernetes on the Google Kubernetes Engine (GKE), using Kubernetes' feature StatefulSet. Contains example Kubernetes YAML resource files (in the 'resource' folder), Terraform infrastructure files (in the 'terraform' folder) and associated Kubernetes based Bash scripts (in the 'scripts' folder) to configure the environment and deploy a MongoDB Replica Set. There are also two projects to load test the cluster in the 'loadtesting' folder (explained in '3 Load Testing').

For further background information on what these scripts and resource files do, plus general information about running MongoDB with Kubernetes, see: [http://k8smongodb.net/](http://k8smongodb.net/)


## 1 How To Run

### 1.1 Prerequisites

Ensure the following dependencies are already fulfilled on your host Linux/Windows/Mac Workstation/Laptop:

1. An account has been registered with the Google Compute Platform (GCP). You can sign up to a [free trial](https://cloud.google.com/free/) for GCP. Note: The free trial places some restrictions on account resource quotas, in particular restricting storage to a maximum of 100GB.
2. GCP’s client command line tool [gcloud](https://cloud.google.com/sdk/docs/quickstarts) has been installed on your local workstation. 
3. Your local workstation has been initialised to: (1) use your GCP account, (2) install the Kubernetes command tool (“kubectl”), (3) configure authentication credentials, and (4) set the default GCP zone to be deployed to:

    ```
    $ gcloud init
    $ gcloud components install kubectl
    $ gcloud auth application-default login
    $ gcloud config set compute/zone europe-west1-b
    ```

**Note:** To specify an alternative zone to deploy to, in the above command, you can first view the list of available zones by running the command: `$ gcloud compute zones list`

### 1.2 Deployment

To build the infrastructure, you can create your own Kubernetes cluster on GKE or use one of the included files: `terraform/gkecluster.tf` or `scripts/createCluster.sh`. Edit the one of the according files to your preferences.

To use terraform, you should supply a Google Cloud service account key at `terraform/creds/serviceaccount.json`.

To provision the cluster, use a command-line terminal/shell and execute the following (first change the variables in the file "resources/config", if appropriate):

    $ cd scripts
    $ ./generate.sh
    
This takes a few minutes to complete. Once completed, you should have a MongoDB Sharded Cluster initialised, secured and running in some Kubernetes StatefulSets. The executed bash script will have created the following resources:

* 3x Replicas of a Config Server Replica Set (k8s deployment type: "StatefulSet")
* 3x Shards with each Shard being a Replica Set containing 1x Primary, 1x Secondary and 1x Arbiter (k8s deployment type: "StatefulSet")
* 2x Mongos Routers, scaling with a hpa up to x30 (k8s deployment type: "StatefulSet")

The amount of shards and other parameters can be configured in `resources/config`.

You can view the list of Pods that contain these MongoDB resources, by running the following:

    $ kubectl get pods
    
You can also view the the state of the deployed environment via the [Google Cloud Platform Console](https://console.cloud.google.com) (look at both the “Kubernetes Engine” and the “Compute Engine” sections of the Console).

The running mongos routers will be accessible to any "app tier" containers, that are running in the same Kubernetes cluster, via the following hostnames and ports (remember to also specify the username and password, when connecting to the database):

    mongos-router-0.mongos-router-service.default.svc.cluster.local:27017
    mongos-router-1.mongos-router-service.default.svc.cluster.local:27017

### 1.3 Test Sharding Your Own Collection

To test that the sharded cluster is working properly, a test script is included at `scripts/configureDB.sh`. This script will create a sharded database called "my-database" along with a sharded collection called "pet" (also see part 3 Load Testing).

Alternatively, you can do this manually by connecting to a "mongos" router, then use the Mongo Shell to authenticate, enable sharding on a specific collection, add some test data to this collection and then view the status of the Sharded cluster and collection:

    $ kubectl exec -it mongos-router-0 -c mongos-container bash
    $ mongo
    > db.getSiblingDB('admin').auth("main_admin", "abc123");
    > sh.enableSharding("my-database");
    > db.pet.ensureIndex({_id : "hashed"});
    > sh.shardCollection("my-database.pet", {"_id" : "hashed"});
    > use my-database;
    > db.pet.insert({"name": "Frieda", "species": "Dog", "breed": "Scottish Terrier"});
    > db.pet.find();
    > sh.status();
    > db.stats();

If everything is working properly, the objects should be scattered across all shards.
    
```
mongos> db.stats()
{
	"raw" : {
		"Shard3RepSet/mongod-shard3-0.mongodb-shard3-service.default.svc.cluster.local:27017,mongod-shard3-1.mongodb-shard3-service.default.svc.cluster.local:27017" : {
			"db" : "my-database",
			"collections" : 1,
			"views" : 0,
			"objects" : 1935,
			"avgObjSize" : 122.03617571059432,
			"dataSize" : 236140,
			"storageSize" : 73728,
			"numExtents" : 0,
			"indexes" : 2,
			"indexSize" : 172032,
			"fsUsedSize" : 4796694528,
			"fsTotalSize" : 101241290752,
			"ok" : 1
		},
		"Shard1RepSet/mongod-shard1-0.mongodb-shard1-service.default.svc.cluster.local:27017,mongod-shard1-1.mongodb-shard1-service.default.svc.cluster.local:27017" : {
			"db" : "my-database",
			"collections" : 1,
			"views" : 0,
			"objects" : 1904,
			"avgObjSize" : 122.02100840336135,
			"dataSize" : 232328,
			"storageSize" : 73728,
			"numExtents" : 0,
			"indexes" : 2,
			"indexSize" : 167936,
			"fsUsedSize" : 5040947200,
			"fsTotalSize" : 101241290752,
			"ok" : 1
		},
		"Shard2RepSet/mongod-shard2-0.mongodb-shard2-service.default.svc.cluster.local:27017,mongod-shard2-1.mongodb-shard2-service.default.svc.cluster.local:27017" : {
			"db" : "my-database",
			"collections" : 1,
			"views" : 0,
			"objects" : 1886,
			"avgObjSize" : 122.01060445387063,
			"dataSize" : 230112,
			"storageSize" : 73728,
			"numExtents" : 0,
			"indexes" : 2,
			"indexSize" : 167936,
			"fsUsedSize" : 4569104384,
			"fsTotalSize" : 101241290752,
			"ok" : 1
		}
	},
	"objects" : 5725,
	"avgObjSize" : 122,
	"dataSize" : 698580,
	"storageSize" : 221184,
	"numExtents" : 0,
	"indexes" : 6,
	"indexSize" : 507904,
	"fileSize" : 0,
	"extentFreeList" : {
		"num" : 0,
		"totalSize" : 0
	},
	"ok" : 1,
	"operationTime" : Timestamp(1555589120, 1),
	"$clusterTime" : {
		"clusterTime" : Timestamp(1555589120, 1),
		"signature" : {
			"hash" : BinData(0,"AAAAAAAAAAAAAAAAAAAAAAAAAAA="),
			"keyId" : NumberLong(0)
		}
	}
}
```

### 1.4 Undeploying & Cleaning Down the Kubernetes Environment

**Important:** This step is required to ensure you aren't continuously charged by Google Cloud for an environment you no longer need.

Run the following script to undeploy the MongoDB Services & StatefulSets plus related Kubernetes resources, followed by the removal of the GCE disks before finally deleting the GKE Kubernetes cluster.

    $ ./teardown.sh
    
It is also worth checking in the [Google Cloud Platform Console](https://console.cloud.google.com), to ensure all resources have been removed correctly.

## 2 Monitoring

This project uses helm to install the prometheus operator stack, containing Prometheus, grafana & mongodb-prometheus-exporter. After generating the cluster, the grafana service will be exposed. A custom grafana dashboard for MongoDB is available in the `resources/dashboards` folder.

The Prometheus-operator stack and Prometheus-MongoDB-exporter can be configured in the HELM charts located under `resources/helm`.

## 3 Load Testing

The loadtesting folder contains 2 docker projects to help with load testing.

* Pets application (springboot app)
* Jmeter project using rest api calls for supplying load

### 3.1 Pets

To build the pets application, set the correct connection string in `pets-app/src/main/resources/application.properties`.
Use maven to package the application to a .jar file with `mvn package`. Then use Docker to build the image when maven is done packaging:

    $ docker build -t pets .


When running the application, it will connect to the database and collection that was configured in the supplied connection string. Then you can use Postman or Jmeter to send POST/GET/PUT/DELETE calls to the application.

### 3.2 Jmeter

To build the jmeter image, set the ip address of the pets app in the `jmeter-docker/scripts/config` file. Then use Docker to build the image:

    $ docker build -t jmeter .


When running this image, it will send POST/GET/PUT/DELETE calls in an infinite loop (at 300 threads) to the ip adress which was supplied in the config file.
