# nomad-consul-jenkins

Vagrantfile to create nomad and consul master, two nomad workers, one nginx server for reverse proxy and jenkins server for app deployments.

Single node master (with nomad and consul) is used due to local env limitation, consul and nomad master should be separated with 3 node (minimum) cluster.

## Requirements

This project is tested on VirtualBox Build 5.2.22 and Vagrant 2.2.2, install [VirtualBox Build 5.2.22](https://www.virtualbox.org/wiki/Download_Old_Builds_5_2) and [Vagrant](https://www.vagrantup.com/downloads.html)  on your local system. Once vagrant is installed, install vbguest plugin as well using below command.

```bash
vagrant plugin install vagrant-vbguest
```

## Usage

---

To clone repository

```bash
git clone https://github.com/faisalshah11/nomad-consul-jenkins.git
cd nomad-consul-jenkins/nomad/
```

---

Provision infrastructure with following IP addresses:

master-server   -> 10.10.10.10\
worker-1        -> 10.10.10.20\
worker-2        -> 10.10.10.30\
fabio-lb        -> 10.10.10.40 (optional)\
nginx (proxy)   -> 10.10.10.50\
jenkins         -> 10.10.10.60

```bash
vagrant up --provision 
```
---

Jenkins server is provisioned with jobs, you just need to signup on jenkins page (10.10.10.60:8080) and you will be able to deploy application from there.

First run **DEPLOY-AIRPORTv101-COUNTRYv101** job to deploy 101 version of both applications.

Now when commit is made on airport repository, jenkins will update the airport service with 110 version.

---


Nomad: 10.10.10.10:4646
Consul: 10.10.10.10:8500
Jenkins: 10.10.10.60:8080


Following endpoints will become available after successful deployment,

```bash
10.10.10.50:8000/airports
10.10.10.50:8000/countries
```

Services can not be accessed directly from outside world, and will only respond to requests from proxy server.

---
