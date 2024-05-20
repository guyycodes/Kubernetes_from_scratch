# Setup the Kube API load balancer
- ssh into the load balancer & install nginx
- create a new directory (WE WIL USE A TCP STREAM - A FEATURE OF NGINX) - This sets up up Nginx as a load balancer
```
sudo apt-get -y install nginx-full

// enable nginx to start automatically on system start
sudo systemctl enable nginx
sudo systemctl status nginx
sudo mkdir -p /etc/nginx/tcpconf.d
```
- next we will edit the main Nginx config file - use command
```
sudo nano /etc/nginx/nginx.conf
/// go the the very bottom of the file that opens up and add the following line:
include /etc/nginx/tcpconf.d/*;
/// this puts the tcp stream configuration file into the nginx server
```
- NOW WE NEED TO CREATE THE CONFIGURATION
- Set variables: these need to be the IP addresses of the upstream controller node(s) we will load balance our traffic to:
    * CONTROLLER0_IP=192.168.30.10
```
/// now set the configuration file for the tcp stream
cat << EOF | sudo tee /etc/nginx/tcpconf.d/kubernetes.conf
stream {

    # this is a pass through setup, we are not decrypting, were using Nginx as a TCP/UDP load balancertraffic so no certificates are needed

    log_format basic '$remote_addr [$time_local] '
                        '$protocol $status $bytes_sent $bytes_received '
                        '$session_time';

    upstream kubernetes {
        server $CONTROLLER0_IP:6443;

    }

    server{
        listen 6443;
        listen 443;
        proxy_pass kubernetes;
        access_log /var/log/nginx/stream_access.log basic;
    }
}
EOF
```
- Reload nginx so it can pickup the configuration
```
sudo nginx -s reload

/// test the load balancer from your local machine:
curl -k https://localhost:6443/version
// response should cone from the control node
```

# setup logging for the load balancer
```
// create the log file and allow it to be written to:
sudo touch /var/log/nginx/stream_access.log

// you may have to update the ownership and permissions for the Nginx stream access log file
sudo chown www-data:www-data /var/log/nginx/stream_access.log

sudo systemctl reload nginx
sudo systemctl restart nginx

// view dynamic logs 
tail -f /var/log/nginx/stream_access.log

```