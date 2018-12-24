#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
wget http://nginx.org/keys/nginx_signing.key
apt-key add nginx_signing.key
apt-get update -y && apt-get install jq htop telnet nginx -y
echo -e "domain node.consul\nsearch node.consul service.consul\nnameserver 10.10.10.50\nnameserver 8.8.8.8\nnameserver 127.0.0.1" > /etc/resolv.conf

rm -f /var/www/html/* /etc/nginx/sites-enabled/*

mkdir /tmp/unpack
consul_datadir=/var/consul

export DEBIAN_FRONTEND=noninteractive

mkdir -p $consul_datadir

apt-get update -y && apt-get install jq htop wget curl unzip -y


cd /tmp/unpack
curl -O https://releases.hashicorp.com/consul/1.4.0/consul_1.4.0_linux_amd64.zip
unzip consul*.zip
mv consul /usr/local/bin/
cd -

cat > /etc/consul.json <<-EOF

{
  "autopilot": {
    "cleanup_dead_servers": true
  },
  "acl_master_token":"7b1e3d26-328d-40ed-8432-946a1affd5b7",
  "acl_token": "anonymous",
  "advertise_addr":  "10.10.10.50",
  "advertise_addr_wan": "10.10.10.50",
  "bind_addr": "0.0.0.0",
  "client_addr": "0.0.0.0",
  "data_dir": "/var/consul",
  "datacenter": "dc1",
  "encrypt": "2KVIYVZRMc3DM9XZQUd10A==",
  "node_name": "nginx",
  "ports": {
"dns": 53
  },
  "raft_protocol": 3,
  "dns_config": [ {"enable_truncate": true} ],
  "recursors": ["8.8.8.8","10.10.10.50"],
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



cat << app > /etc/nginx/sites-enabled/app.conf

upstream app  {
  server 10.10.10.20:10502;
  server 10.10.10.30:10501;
}

server {
  
  listen 8000;
  listen [::]:8000;

  server_name demo.local;

  location / {
    root /var/www/html;
  }

  location /countries {
	  proxy_pass http://10.10.10.20:10502;
  }

  location /airports {
	  proxy_pass http://10.10.10.30:10501;
  }

  location /search {
	  proxy_pass http://10.10.10.30:10501;
  }

  location /health {
    proxy_pass http://app;
  }
}

app

cat << index > /var/www/html/index.html
<h1>Guide</h1>
<ul>
<li>
<h4>country-service: a service which returns basic information about countries</h4>
<p>- Endpoint: /countries to get a full list of countries</p>
<p>- Endpoint: /countries/&lt;query&gt;</p>
</li>
<li>
<h4>airport-service</h4>
<p>Version 1.0.1: a service which returns information about airports with country codes</p>
<p>- Endpoint: /airports to get a full list of airports and their runways</p>
<p>- Endpoint: /airports/&lt;query&gt; to get a list of airports based on country code (e.g.: "NL")</p>
<p>Version 1.1.0: a service which returns information about airports with country codes</p>
<p>- Endpoint: /airports?full=[0|1]</p>
<p>- Endpoint: /airports/&lt;id&gt;</p>
<p>- Endpoint: /search/&lt;qry</p>
</li>
</ul>
index

systemctl enable nginx
systemctl restart nginx