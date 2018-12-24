#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
apt-get -y install openjdk-8-jre
mkdir /var/lib/jenkins	/tmp/jenkins
useradd -U -r -s /sbin/nologin jenkins
curl -s -L http://ftp-chi.osuosl.org/pub/jenkins/war/2.156/jenkins.war > /usr/lib/jenkins.war

curl -o /tmp/jenkins.tar.gz -L https://www.dropbox.com/s/e7lnjg6jr0v5n2n/jenkins.tar.gz?dl=0

tar -xzf /tmp/jenkins.tar.gz -C /var/lib/jenkins

cat > /etc/systemd/system/jenkins.service <<-EOF
	[Unit]
	Description=Jenkins
	After=network.target
	Requires=network.target
	Wants=var-lib-jenkins.mount
	
	[Service]
	Type=simple
	Environment=JENKINS_HOME=/var/lib/jenkins
	ExecStart=/usr/bin/java -XX:MaxHeapSize="512m" -Djava.awt.headless=true -Djenkins.install.runSetupWizard=false -Dorg.jenkinsci.plugins.gitclient.Git.timeOut="60" -jar /usr/lib/jenkins.war
	Restart=always
	User=root
	RestartSec=20
	
	[Install]
	WantedBy=multi-user.target
EOF
systemctl enable jenkins.service
systemctl start jenkins.service

echo -e "domain node.consul\nsearch node.consul service.consul\nnameserver 10.10.10.60\nnameserver 8.8.8.8\nnameserver 127.0.0.1" > /etc/resolv.conf
mkdir /tmp/unpack
consul_datadir=/var/consul

mkdir -p $consul_datadir

apt-get update -y && apt-get install htop wget curl unzip -y


cd /tmp/unpack
curl -O https://releases.hashicorp.com/consul/1.4.0/consul_1.4.0_linux_amd64.zip
unzip consul*.zip
mv consul /usr/local/bin/
cd -

echo -e "domain node.consul\nsearch node.consul service.consul\nnameserver 10.10.10.20\nnameserver 8.8.8.8\nnameserver 127.0.0.1" > /etc/resolv.conf

cat > /etc/consul.json <<-EOF

{
  "autopilot": {
    "cleanup_dead_servers": true
  },
  "acl_master_token":"7b1e3d26-328d-40ed-8432-946a1affd5b7",
  "acl_token": "anonymous",
  "advertise_addr":  "10.10.10.60",
  "advertise_addr_wan": "10.10.10.60",
  "bind_addr": "0.0.0.0",
  "client_addr": "0.0.0.0",
  "data_dir": "/var/consul",
  "datacenter": "dc1",
  "encrypt": "2KVIYVZRMc3DM9XZQUd10A==",
  "node_name": "jenkins",
  "ports": {
"dns": 53
  },
  "raft_protocol": 3,
  "dns_config": [ {"enable_truncate": true} ],
  "recursors": ["8.8.8.8","10.10.10.60"],
  "retry_join": ["10.10.10.10"]
}
EOF

cat > /etc/systemd/system/consul.service <<-EOF
	[Unit]
	Description=consul agent
	Requires=network-online.target
	After=network-online.target
	[Service]
	Restart=on-failure
	ExecStart=/usr/local/bin/consul agent -config-file=/etc/consul.json
	ExecReload=/bin/kill -HUP \$MAINPID
	KillSignal=SIGINT
	[Install]
	WantedBy=multi-user.target
EOF
chmod +x /usr/local/bin/consul 
mkdir -p "/var/lib/consul" 
systemctl enable consul.service
systemctl start consul.service
systemctl restart docker