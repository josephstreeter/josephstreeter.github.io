# Nginx

## Reverse Proxy

### Setup

Docker containers will be used to demonstrate using Nginx as a reverse proxy. Create a directory to hold all of the required sub-directories and files.

Create a sub-directory to hold files for each of the containers.

```bash
mkdir webserver1
mkdir webserver2
mkdir nginx
```

In each "webserver*" folder create an ```index.html``` file with content specific to that webserver so that it is obvious which webserver the request is being sent to.

```html
<h1>Web Server 1</h1>
```

Create a file named ```nginx.conf``` in the "nginx" directory and add the following code:

```text
worker_processes 1;

events { worker_connections 1024; }


http {

    log_format compression '$remote_addr - $remote_user [$time_local] '
        '"$request" $status $upstream_addr '
        '"$http_referer" "$http_user_agent" "$gzip_ratio"';

    proxy_set_header   X-Real-IP $remote_addr;
    proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header   X-Forwarded-Host $server_name;
}
```

Create a file in the root of the directory named ```docker-compose.yml``` and save with the following Docker Compose Yaml:

```yml
version : "3.9"
services :
  
  apache1:
    image: httpd:latest
    container_name: my-apache-app1
    volumes:
    - ./website1:/usr/local/apache2/htdocs
  
  apache2:
    image: httpd:latest
    container_name: my-apache-app2
    volumes:
    - ./website2:/usr/local/apache2/htdocs

  nginx:
    image: nginx:latest
    container_name: nginx
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
    ports:
      - 80:80
```

Create the environment by running the following Docker Compose command in the root of the directory.

```bash
docker-compose up -d
```

### Reverse Prozy - Sites on Separate Ports

Update the ```nginx.conf``` file by adding the upstream sections and the virtual server sections for each of the webservers has shown below:

```text
worker_processes 1;

events { worker_connections 1024; }


http {

    log_format compression '$remote_addr - $remote_user [$time_local] '
        '"$request" $status $upstream_addr '
        '"$http_referer" "$http_user_agent" "$gzip_ratio"';

    upstream webserver1 {
        server my-apache-app1:80;
    }

    upstream webserver2 {
        server my-apache-app2:80;
    }

    proxy_set_header   X-Real-IP $remote_addr;
    proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header   X-Forwarded-Host $server_name;
    
    server {
        listen 8081;
        access_log /var/log/nginx/access.log compression;
        
        location / {
            proxy_pass         http://webserver1;
        }
    }

    server {
        listen 8082;
        access_log /var/log/nginx/access.log compression;

        location / {
            proxy_pass         http://webserver2;
        }
    }
}
```

Update the the nginx configuration by running the following Docker Compose commands in the root of the directory.

```bash
docker-compose down && docker-compose up -d
```

Testing the setup with curl should show you the page from each of the web server containers based on the url used.

```bash
curl http://localhost:8081
curl http://localhost:8082
```

### Reverse Proxy - Sites on Single Port

Create two entries in the ```/etc/hosts``` file for each of the webservers.

```text
127.0.0.1   site1.joseph-streeter.com
127.0.0.1   site2.joseph-streeter.com
```

Update the ```nginx.conf``` file to include a ```server_name``` directive for each virtual server as shown below:

```text
worker_processes 1;

events { worker_connections 1024; }


http {

    log_format compression '$remote_addr - $remote_user [$time_local] '
        '"$request" $status $upstream_addr '
        '"$http_referer" "$http_user_agent" "$gzip_ratio"';

    upstream webserver1 {
        server my-apache-app1:80;
    }

    upstream webserver2 {
        server my-apache-app2:80;
    }

    proxy_set_header   X-Real-IP $remote_addr;
    proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header   X-Forwarded-Host $server_name;
    
    server {
        listen 80;
        access_log /var/log/nginx/access.log compression;
        server_name site1.joseph-streeter.com;
        
        location / {
            proxy_pass         http://webserver1;
        }
    }

    server {
        listen 80;
        access_log /var/log/nginx/access.log compression;
        server_name site2.joseph-streeter.com;

        location / {
            proxy_pass         http://webserver2;
        }
    }
}
```

Update the the nginx configuration by running the following Docker Compose commands in the root of the directory.

```bash
docker-compose down && docker-compose up -d
```

Testing the setup with curl should show you the page from each of the web server containers based on the url used.

```bash
curl http://site1.joseph-streeter.com
curl http://site2.joseph-streeter.com
```

## Load Balancer

Nginx can be used to load balance requests accross multiple instances of an application. This provides fault tollerance and optimizes resource utilization, throughput, and latency.

Use the same setup as before to dempnstrate load balancing. Move the ```server my-apache-app2``` to the ```upstream webserver``` under ```server my-apache-app1``` and remove the ```upstream webserver2``` from the file. Then remove the virtual server section for ```site2.joseph-streeter.com```.

```text
worker_processes 1;

events { worker_connections 1024; }


http {

    log_format compression '$remote_addr - $remote_user [$time_local] '
        '"$request" $status $upstream_addr '
        '"$http_referer" "$http_user_agent" "$gzip_ratio"';

    upstream webserver1 {
        server my-apache-app1:80;
        server my-apache-app2:80;
    }

    proxy_set_header   X-Real-IP $remote_addr;
    proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header   X-Forwarded-Host $server_name;
    
    server {
        listen 80;
        access_log /var/log/nginx/access.log compression;
        server_name site1.joseph-streeter.com;
        
        location / {
            proxy_pass         http://webserver1;
        }
    }
}
```

Test the configuration with the curl command:

```bash
for i in {1..10}
do 
    curl http://site1.joseph-streeter.com:81
done
```

The output should alternate between the two hosts if set up correctly.

```console
<h1>Web Server 1</h1>
<h1>Web Server 2</h1>
<h1>Web Server 1</h1>
<h1>Web Server 2</h1>
<h1>Web Server 1</h1>
<h1>Web Server 2</h1>
<h1>Web Server 1</h1>
<h1>Web Server 2</h1>
<h1>Web Server 1</h1>
<h1>Web Server 2</h1>
```

### Load Balancing Options

Nginx can use the following load balancing methods:

- **round-robin** — requests to the application servers are distributed in a round-robin fashion.
- **least-connected** — next request is assigned to the server with the least number of active connections.
- **ip-hash** — a hash-function is used to determine what server should be selected for the next request (based on the client’s IP address)

#### Round Robin

Round Robin is the simplest method and is the default method. In the following example, all requests sent to ```http://app1``` are proxied to the ```app``` server group and distributed between the listed servers in a round-robin fashion.

```text
http {
    upstream app1 {
        server srv1.example.com;
        server srv2.example.com;
        server srv3.example.com;
    }

    server {
        listen 80;

        location / {
            proxy_pass http://app1;
        }
    }
}
```

#### Least Connected

Least connected attempts to prevent any one server from being overloaded by distributing requests to servers that have fewer connections. Least Connected load balancing is configured by adding the ```least_conn``` directive to the server (upstream) group configuration.

```text
http {
    upstream app1 {
        least_conn;
        server srv1.example.com;
        server srv2.example.com;
        server srv3.example.com;
    }

    server {
        listen 80;

        location / {
            proxy_pass http://app1;
        }
    }
}
```

> [!NOTE]
> Session Persistance - Neither round-robin or least-connected load balancing persist sessions. There is no guarantee that a client will be directed to the same server. If session persistance is required, ip-hash needs to be used.

#### IP-Hash

the ip-hash method uses the client’s IP address as a hashing key to determine which server in a server group should be selected for the client’s requests. This method ensures that the requests from the same client will always be directed to the same server except when this server is unavailable.

The ip-hash method can be used if application being load-balances required session persistance.

To configure ip-hash load balancing, just add the ```ip_hash``` directive to the server (upstream) group configuration:

```text
upstream myapp1 {
    ip_hash;
    server srv1.example.com;
    server srv2.example.com;
    server srv3.example.com;
}
```

#### Weighted Load Balancing

The weight parameter...

```text
upstream myapp1 {
        server srv1.example.com weight=3;
        server srv2.example.com;
        server srv3.example.com;
    }
```

#### Health Checks

## Resources

- [Nginx Load Balancing](http://nginx.org/en/docs/http/load_balancing.html)
