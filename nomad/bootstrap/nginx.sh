#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
wget http://nginx.org/keys/nginx_signing.key
apt-key add nginx_signing.key
apt-get update -y && apt-get install jq htop telnet nginx -y
echo -e "domain node.consul\nsearch node.consul service.consul\nnameserver 10.10.10.50\nnameserver 8.8.8.8\nnameserver 127.0.0.1" > /etc/resolv.conf

rm -f /var/www/html/* /etc/nginx/sites-enabled/*





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