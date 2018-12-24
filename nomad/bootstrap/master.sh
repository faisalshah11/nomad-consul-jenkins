#!/bin/bash

mkdir /tmp/unpack
consul_datadir=/var/consul
nomad_datadir=/var/nomad

mkdir -p $nomad_datadir
mkdir -p $consul_datadir
export DEBIAN_FRONTEND=noninteractive
apt-get update -y && apt-get install jq wget curl unzip -y

### consul ###

cd /tmp/unpack
curl -O https://releases.hashicorp.com/consul/1.4.0/consul_1.4.0_linux_amd64.zip
unzip consul*.zip
mv consul /usr/local/bin/
cd -

echo -e "domain node.consul\nsearch node.consul service.consul\nnameserver 10.10.10.10\nnameserver 8.8.8.8\nnameserver 127.0.0.1" > /etc/resolv.conf


cat > /etc/consul.json <<-EOF
{
  "autopilot": {
    "cleanup_dead_servers": true
  },
  "acl_master_token":"7b1e3d26-328d-40ed-8432-946a1affd5b7",
  "acl_token": "anonymous",
  "advertise_addr":  "10.10.10.10",
  "advertise_addr_wan": "10.10.10.10",
  "bind_addr": "0.0.0.0",
  "client_addr": "0.0.0.0",
  "data_dir": "/var/consul",
  "datacenter": "dc1",
  "encrypt": "2KVIYVZRMc3DM9XZQUd10A==",
  "node_name": "master-server",
  "ports": {"dns": 53},
  "raft_protocol": 3,
  "dns_config": [ {"enable_truncate": true} ],
  "recursors": ["8.8.8.8","10.10.10.10"],
  "retry_join": ["10.10.10.10"],
  "ui":     true,
  "server": true,
  "retry_join_wan": ["10.10.10.10"],
  "bootstrap_expect" : 1
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

### nomad ###

cat > /etc/nomad.hcl <<-EOF
data_dir  = "/var/nomad"
bind_addr = "0.0.0.0"
advertise {
  http = "10.10.10.10"
  rpc  = "10.10.10.10"
  serf = "10.10.10.10" 
}
datacenter = "dc1"
server {
        enabled          = true
        bootstrap_expect = 1 # this should not be hard coded
}
EOF

cd /tmp/unpack
curl -O https://releases.hashicorp.com/nomad/0.8.6/nomad_0.8.6_linux_amd64.zip
unzip nomad*.zip
mv nomad /usr/local/bin/
cd -


cat > /etc/systemd/system/nomad.service <<-EOF
    [Unit]
    Description=nomad agent
    Requires=consul.service
    After=consul.service
    [Service]
    Restart=on-failure
    ExecStart=/usr/local/bin/nomad agent -config=/etc/nomad.hcl
    ExecReload=/bin/kill -HUP $MAINPID
    KillSignal=SIGINT
    [Install]
    WantedBy=multi-user.target
EOF
chmod +x /usr/local/bin/nomad
mkdir -p "/var/lib/nomad" 
systemctl enable nomad.service
systemctl start nomad.service