# Setup HTTP Health checks
##### The load balancer can know which nodes are up, healthy and unhealthy so it can distribute traffic
- Check control plane health
```
curl -k https://localhost:6443/healthz
// if you were to try this via http it wouldnt work
```
- We will setup an Nginx proxy server on the control plane that can call the https endpoint using http: This allows ups to Check the health of the cluster via http
```
/// Install Nginx
sudo apt-get -y install nginx

// input this command
cat > kubernetes.default.svc.cluster.local << EOF
server{
    listen  80;
    server_name kubernetes.default.svc.cluster.local;

    # Restrict access to a specific IP
   # allow 192.168.10.252;
   # deny all;  # Deny everyone else

    location /healthz {
        proxy_pass https://127.0.0.1:6443/healthz;
        proxy_ssl_trusted_certificate /var/lib/kubernetes/ca.pem;
    }

    location /version {
        proxy_pass      https://127.0.0.1:6443/version;
        proxy_ssl_trusted_certificate /var/lib/kubernetes/ca.pem;
    }
}
EOF
```
- Move this file in the proper location:
```
sudo mv kubernetes.default.svc.cluster.local /etc/nginx/sites-available/kubernetes.default.svc.cluster.local

/// create a symlink (allows for easy enabling an disabling of different configurations by adding or changing the symlinks)
sudo ln -s /etc/nginx/sites-available/kubernetes.default.svc.cluster.local /etc/nginx/sites-enabled/

///restart nginx so it picks up the changes
sudo systemctl restart nginx

///enable nginx to start up when the server starts up
sudo systemctl enable nginx
sudo systemctl status nginx

// test the nginx server - http default port is port 80
curl -H "Host: kubernetes.default.svc.cluster.local" http://192.168.30.10/version
curl -H "Host: kubernetes.default.svc.cluster.local" -i http://192.168.30.10/healthz
```

# Seting up RBAC for Kublet Authorization
- (Role Based Access Control)
- We need to make sure the kubernetes api has permissions to access the kubernetes api on each kublet node and perform common tasks
```
cat << EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:kube-apiserver-to-kubelet
rules:
  - apiGroups:
      - ""
    resources:
      - nodes/proxy
      - nodes/stats
      - nodes/log
      - nodes/spec
      - nodes/metrics
    verbs:
      - get
      - list
      - watch
      - create
      - delete
      - update
      - patch
EOF

//////////////////////////////////////////////////////////////////////////////////////
/// next assign the role to the default user using ClusterRole Binding and apply it///
//////////////////////////////////////////////////////////////////////////////////////

cat << EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:kube-apiserver
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-apiserver-to-kubelet
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: Kubernetes
EOF
```

## Mores EXAMPLES of Role Based Access Control exmamples
#### Create a ClusterRole for Lease Access
```
cat << EOF | sudo tee /etc/kubernetes/config/kube-controller-manager-lease-clusterrole.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: kube-controller-manager-lease
rules:
- apiGroups: ["coordination.k8s.io"]
  resources: ["leases"]
  verbs: ["get", "update", "create"]
  resourceNames: ["kube-controller-manager"]
EOF
```
##### Step 2: Apply the ClusterRole
```
kubectl apply -f /etc/kubernetes/config/kube-controller-manager-lease-clusterrole.yaml --kubeconfig admin.kubeconfig
```
##### Step 3: Create a ClusterRoleBinding 
```
cat << EOF | sudo tee /etc/kubernetes/config/kube-controller-manager-lease-clusterrolebinding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kube-controller-manager-lease
subjects:
- kind: User
  name: system:kube-controller-manager
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: kube-controller-manager-lease
  apiGroup: rbac.authorization.k8s.io
EOF
```
##### Step 4: Apply the ClusterRoleBinding
```
kubectl apply -f /etc/kubernetes/config/kube-controller-manager-lease-clusterrolebinding.yaml --kubeconfig admin.kubeconfig
```

