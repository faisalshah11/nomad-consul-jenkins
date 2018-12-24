#!/bin/bash

mkdir /tmp/unpack
consul_datadir=/var/consul
nomad_datadir=/var/nomad
export DEBIAN_FRONTEND=noninteractive
mkdir -p $nomad_datadir
mkdir -p $consul_datadir

apt-get update -y && apt-get install jq htop wget curl unzip -y


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
  "advertise_addr":  "10.10.10.20",
  "advertise_addr_wan": "10.10.10.20",
  "bind_addr": "0.0.0.0",
  "client_addr": "0.0.0.0",
  "data_dir": "/var/consul",
  "datacenter": "dc1",
  "encrypt": "2KVIYVZRMc3DM9XZQUd10A==",
  "node_name": "worker-1",
  "ports": {
"dns": 53
  },
  "raft_protocol": 3,
  "dns_config": [ {"enable_truncate": true} ],
  "recursors": ["8.8.8.8","10.10.10.20"],
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



cat > /etc/nomad.hcl <<-EOF
data_dir  = "/var/nomad"
bind_addr = "0.0.0.0"
datacenter = "dc1"
advertise {
  http = "10.10.10.20"
  rpc  = "10.10.10.20"
  serf = "10.10.10.20" 
}
client {
  enabled       = true
  network_interface = "eth1"
  meta {
"exclusive" = "worker-1"
  }
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
systemctl restart docker

##### restricting access to container to nginx and master

# Create a PRE_DOCKER table
iptables -N PRE_DOCKER

# Default action
iptables -I PRE_DOCKER -j REJECT

# Docker Containers Restricted LAN Access
iptables -I PRE_DOCKER -i eth1 -s 10.10.10.50 -j ACCEPT
iptables -I PRE_DOCKER -i eth1 -s 10.10.10.10 -j ACCEPT

# Docker internal use
iptables -I PRE_DOCKER -o docker0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -I PRE_DOCKER -i docker0 ! -o docker0 -j ACCEPT
iptables -I PRE_DOCKER -m state --state RELATED -j ACCEPT
iptables -I PRE_DOCKER -i docker0 -o docker0 -j ACCEPT

# Finally insert the PRE_DOCKER table before the DOCKER table in the FORWARD chain.
iptables -I FORWARD -o docker0 -j PRE_DOCKER

apt-get install iptables-persistent -y

