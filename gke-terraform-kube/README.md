## Table of Contents
* [About the repo](#about-the-repo)
* [Quick start](#quick-start)
* [Repository structure](#repository-structure)
   * [terraform-modules](#terraform-modules)
   * [test-cluster](#test-cluster)
   * [accounts](#accounts)

## About the repo
This repository contains an example of deploying and managing [Kubernetes](https://kubernetes.io/) clusters to [Google Cloud Platform](https://cloud.google.com/) (GCP) in a reliable and repeatable way.

[Terraform](https://www.terraform.io/) is used to describe the desired state of the infrastructure, thus implementing Infrastructure as Code (IaC) approach.

[Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/) (GKE) service is used for cluster deployment. Since Google announced that [they had eliminated the cluster management fees for GKE](https://cloudplatform.googleblog.com/2017/11/Cutting-Cluster-Management-Fees-on-Google-Kubernetes-Engine.html), it became the safest and cheapest way to run a Kubernetes cluster on GCP, because you only pay for the nodes (compute instances) running in your cluster and Google abstracts away and takes care of the master control plane.  


## Quick start
**Prerequisite:** make sure you're authenticated to GCP via [gcloud](https://cloud.google.com/sdk/gcloud/) command line tool using either _default application credentials_ or _service account_ with proper access.

Check **terraform.tfvars.example** file inside `test-cluster` folder to see what variables you need to define before you can use Terraform to create a cluster.

You can run the following command in `test-cluster` to make your variables definitions available to Terraform:
```bash
$ mv terraform.tfvars.example terraform.tfvars # variables defined in terraform.tfvars will be automatically picked up by terraform during the run
```

Once the required variables are defined, use the commands below to create a Kubernetes cluster:
```bash
$ terraform init
$ terraform apply
```

After the cluster is created, run a command from Terraform output to configure access to the cluster via `kubectl` command line tool. The command from Terraform output will be in the form of:

```bash
$ gcloud container clusters get-credentials test-cluster --zone us-west1-b --project example-123456
```


## Repository structure
```bash
├── accounts
│   └── service-accounts
├── test-cluster
│   ├── deploy-app-example
│   └── k8s-config
│       ├── charts
│       │   └── gitlab-omnibus
│       │       ├── charts
│       │       │   └── gitlab-runner
│       │       │       └── templates
│       │       └── templates
│       │           ├── fast-storage
│       │           ├── gitlab
│       │           ├── ingress
│       │           └── load-balancer
│       │               └── nginx
│       ├── env-namespaces
│       ├── kube-lego
│       └── storage-classes
└── terraform-modules
    ├── cluster
    ├── firewall
    │   └── ingress-allow
    ├── node-pool
    └── vpc
```

### terraform-modules
The folder contains reusable pieces of Terraform code which help us manage our configuration more efficiently by avoiding code repetition and reducing the volume of configuration.

The folder contains 4 modules at the moment of writing:

* `cluster` module allows to create new Kubernetes clusters.
* `firewall/ingress-allow` module allows to create firewall rules to filter incoming traffic.
* `node-pool` module is used to create [Node Pools](https://cloud.google.com/kubernetes-engine/docs/concepts/node-pools) which is mechanism to add extra nodes of required configuration to a running Kubernetes cluster. Note that nodes which configuration is specified in the `cluster` module become the _default_ node pool.  
* `vpc` module is used to create new Virtual Private Cloud (VPC) networks.

### test-cluster
Inside the **test-cluster** folder, you'll find the Terraform configuration for creating and managing a Kubernetes cluster.
Important files here:

* `main.tf` is the place where we define main configuration such as creation of a network for our cluster, creation of the cluster itself and node pools.
* `firewall.tf` is used to describe the firewall rules regarding our cluster.
* `dns.tf` is used to manage Google DNS service resources (again with regards to the services and applications which we will run in our cluster).
* `static-ips.tf` is used to manage static IP addresses for services and applications which will be running in the cluster.
* `terraform.tfvars.example` contains example terraform input variables which you need to define before you can start creating a cluster.
* `outputs.tf` contains output variables
* `variables.tf` contains input variables

* `k8-confing` folder contains Kubernetes configuration files (**manifests**) which are used to define configuration of the running Kubernetes cluster.
It has 4 subdirectories inside:
    * `env-namespaces` contains manifests for creating [namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/), or virtual environments withing the cluster, for running our services. In this example, `cmsa-namespaces.yml` file is used to describe 3 namespaces: `cmsa-stage` and `cmsa-prod` for running the example application (which is called cmsa in this case) in different virtual environments, and `infra` namespace for running infrastructure services (CI/CD, monitoring, logging, etc).
    * `storage-classes` folder is used to create storage classes that could be then used in [dynamic volume provisioning](http://blog.kubernetes.io/2017/03/dynamic-provisioning-and-storage-classes-kubernetes.html) for our applications.
    * `kube-lego` folder has the configuration required to run [kube-lego](https://github.com/jetstack/kube-lego) service which is used for automatic SSL certificates requests for our services running inside the cluster.
    * `charts` contains [Helm](https://github.com/kubernetes/helm) charts for deploying infra services. In this case it only has a chart for deploying [Gitlab CI](https://about.gitlab.com/features/gitlab-ci-cd/) along with a Runner.

* `deploy-app-example` has an bunch of Kubernetes objects definitions which are used to deploy nginx to a Kubernetes cluster. You can use the command below to deploy nginx to the cluster once it is created:
	```bash
	$ kubectl apply -f ./deploy-app-example/nginx-example.yml
	```

### accounts
This is another top level folder in this project. It has a separate set of Terraform files which are used to manage access accounts to our clusters. For example, you may want to create a service account for your CI tool to allow it to deploy applications to the cluster.
