Versioned Online Boutique Application achieved through SADP methodology. 

Four different variants are available:
- Normal High Performance
- Normal Low Power
- Basic High Performance 
- Basic Low Power

Those variants can be deployed on a kubernetes cluster using the respective shell scripts contained in the release folder. 

Loadgenerator10/50/100 generated a respective load of users into the application deployed. 

Cluster setup on GCE (Google Compute Engine):

- Enter the Kubernetes Engine section 
- Create cluster 
- GKE Standard
- Cluster basics: name, region (eu-westx-x), release channel (default)
- Node Pools: name, number of nodes (3), Nodes -> image type (Container-Optimized OS with containerd (cos_containerd))
- Series -> N1, Machine Type -> n1-standard-2
- Networking -> Enable HTTP load balancing
- Features -> Enable Cloud Logging (System and Workloads), Enable Cloud Monitoring (System and Workloads)

Cloud Storage Bucket:

- Create bucket
- name, region (europe-west-x), standard, uniform, data encryption (none)

Kubernetes setup after cluster is created:

- Enter the Kubernentes Engine section
- Click connect on the right side of the cluster information 
- Authorize console, and press enter to get the credentials for the cluster
- Istio setup:
  - curl -L https://istio.io/downloadIstio | sh -
  - cd istio-1.13.3
  - export PATH=$PWD/bin:$PATH
  - istioctl install --set profile=demo -y
  - kubectl label namespace default istio-injection=enabled
  - kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.13/samples/addons/prometheus.yaml
  - kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.13/samples/addons/grafana.yaml
- go back into root folder with cd ..
- open a second terminal (Google Cloud Shell) with the + button
- in the new terminal execute 'istioctl dashboard prometheus'
- it should open prometheus on port 9090
- go back into the first terminal
- boutique SADP download:
  - git clone https://github.com/yensky95/boutique-basic.git
- cd boutique-basic/release
- launch one of the three loadgenerator variants with:
  - kubectl apply -f loadgenerator10.yaml<br>
                     loadgenerator50.yaml<br>
                     loadgenerator100.yaml
- launch the autodeploy decision system:
  - bash autodeploy.sh

Docker images build:

- open a terminal inside the path of the microservice folder we want to build (e.g. boutique-basic/src/recommendationservice)
- execute the docker build command:
  -  docker build -t dockerhub_username/desired_name .
- this will create a local image in docker
- push this image to dockerhub (connect docker with dockerhub) with the button in the GUI or with command line 

YAML files image change:

- open the manifest file 
- search for the desired microservice for which we desire to change image
- e.g. below<br>
apiVersion: apps/v1<br>
kind: Deployment<br>
metadata:<br>
  name: loadgenerator<br>
spec:<br>
  selector:<br>
    matchLabels:<br>
      app: loadgenerator<br>
  replicas: 1<br>
  template:<br>
    metadata:<br>
      labels:<br>
        app: loadgenerator<br>
      annotations:<br>
        sidecar.istio.io/rewriteAppHTTPProbers: "true"<br>
    spec:<br>
      serviceAccountName: default<br>
      terminationGracePeriodSeconds: 5<br>
      restartPolicy: Always<br>
      initContainers:<br>
      - command:<br>
        - /bin/sh<br>
        - -exc<br>
        - |<br>
          echo "Init container pinging frontend: ${FRONTEND_ADDR}..."<br>
          STATUSCODE=$(wget --server-response http://${FRONTEND_ADDR} 2>&1 | awk '/^  HTTP/{print $2}')<br>
          if test $STATUSCODE -ne 200; then<br>
              echo "Error: Could not reach frontend - Status code: ${STATUSCODE}"<br>
              exit 1<br>
          fi<br>
        name: frontend-check<br>
        image: busybox:latest<br>
        env:<br>
        - name: FRONTEND_ADDR<br>
          value: "frontend:80"<br>
      containers:<br>
      - name: main<br>
        image: yensky/loadgeneratortenusers:latest  <------ HERE (always put dockerhub_username/name:version_tag)<br>
        env:<br>
        - name: FRONTEND_ADDR<br>
          value: "frontend:80"<br>
        - name: USERS<br>
          value: "10"<br>
        resources:<br>
          requests:<br>
            cpu: 300m<br>
            memory: 256Mi<br>
          limits:<br>
            cpu: 500m<br>
            memory: 512Mi<br>


Transfer a file from VM to Cloud Storage bucket:

- open the Google Cloud Shell
- gsutil cp file_name.xxx gs://bucket_name
- go in the Google Cloud Storage bucket and download