# Check the status of all worker nodes and debug as needed

```
// for reloading after changes to systemd files
sudo systemctl daemon-reload

sudo systemctl enable containerd kubelet kube-proxy
sudo systemctl start containerd kubelet kube-proxy
sudo systemctl status containerd kubelet kube-proxy

// for restarting
sudo systemctl restart containerd kubelet kube-proxy

sudo systemctl status containerd kubelet kube-proxy

// log checking
sudo journalctl -u containerd -f
sudo journalctl -u kubelet -f
sudo journalctl -u kube-proxy -f


sudo journalctl -u containerd | grep kata
sudo journalctl -u containerd | grep runc
```

# startup and shutdown and debug of the Control plane:
- to trouble shoot any issues, use...
```
sudo journalctl -u kube-apiserver -f
sudo journalctl -u kube-controller-manager -f
sudo journalctl -u kube-scheduler -f
sudo journalctl -u etcd -f

// get leases
kubectl get leases

// turn on everything
sudo systemctl start etcd
sudo systemctl start kube-apiserver kube-controller-manager kube-scheduler

// stop everything
sudo systemctl stop etcd kube-apiserver kube-controller-manager kube-scheduler
sudo systemctl stop containerd kubelet kube-proxy
```
# Managing the load balancer
```
sudo systemctl reload nginx
sudo systemctl restart nginx

// view dynamic logs 
tail -f /var/log/nginx/stream_access.log
```