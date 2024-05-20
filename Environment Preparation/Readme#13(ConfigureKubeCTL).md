# Configuring KubeCTL for remote access through the load balancer

* set up your ssh connection to the loab balancer on port 6443:Localhost:6443
```
Host raspberrypiLB
 HostName 192.168.20.251
 User guymorganb
 LocalForward 6443 localhost:6443
```
- Next run this command on your local machine, this will allow you to connect to the load balancer to talk to the cluster
```
kubectl config set-cluster iOTHost \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://localhost:6443
```
- next set your credentials
```
kubectl config set-credentials admin \
  --client-certificate=admin.pem \
  --client-key=admin-key.pem
```
- next set a context (a context is just a way to send data along to a server with a request)
```
kubectl config set-context iOTHOST \
  --cluster=iOTHost \
  --user=admin
```
- now use the context
```
kubectl config set-context iOTHost \
  --cluster=iOTHost \
  --user=admin
```  
* Now to switch to your cluster
```
kubectl config use-context iOTHost
kubectl get nodes
```

