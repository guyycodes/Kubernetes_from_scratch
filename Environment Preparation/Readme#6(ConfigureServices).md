# Setup the kubernetes api server
- The kube API server connects to etcd and servers as a controll point for the cluster

- ssh into the control plane
- make directory for the kubernetes api server
- copy the files into the newly created directory
```
sudo mkdir -p /var/lib/kubernetes
sudo cp ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
    service-account-key.pem service-account.pem \
    encryption-config.yaml /var/lib/kubernetes/
```
##### generate the systemd unit file for kube api server
- set an internal variable
```
INTERNAL_IP=192.168.30.10
CONTROLLER0_IP=192.168.30.10
////////////////////////////

cat << EOF | sudo tee /etc/systemd/system/kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-apiserver \
  --advertise-address=192.168.30.10 \
  --allow-privileged=true \
  --apiserver-count=3 \
  --audit-log-maxage=30 \
  --audit-log-maxbackup=3 \
  --audit-log-maxsize=100 \
  --audit-log-path=/var/log/audit.log \
  --authorization-mode=Node,RBAC \
  --bind-address=0.0.0.0 \
  --client-ca-file=/var/lib/kubernetes/ca.pem \
  --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \
  --etcd-cafile=/var/lib/kubernetes/ca.pem \
  --etcd-certfile=/var/lib/kubernetes/kubernetes.pem \
  --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \
  --etcd-servers=https://192.168.30.10:2379 \
  --event-ttl=1h \
  --encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \
  --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \
  --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \
  --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \
  --runtime-config=api/all=true \
  --service-account-key-file=/var/lib/kubernetes/service-account.pem \
  --service-account-issuer="kubernetes.default.svc" \
  --service-account-signing-key-file="/var/lib/kubernetes/service-account-key.pem" \
  --service-cluster-ip-range=10.32.0.0/24 \
  --service-node-port-range=30000-32767 \
  --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \
  --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \
  --v=5 \
  --kubelet-preferred-address-types=InternalIP,InternalDNS,Hostname,ExternalIP,ExternalDNS
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

- The directive --kubelet-preferred-address-types in the kube-apiserver service configuration specifies an ordered list of preferred address types to assign to Kubelets. This affects the address types the API server uses to communicate with the Kubelets. The options provided in this list dictate how the API server selects the best (top-most preferred) way to reach a Kubelet when various address types are available.

# Setting up the controller manager
- shh into the controller server
- Move the kube controller manager.cubeconfig
```
sudo cp kube-controller-manager.kubeconfig /var/lib/kubernetes
```
- generate the systemd unit file
```
cat << EOF | sudo tee /etc/systemd/system/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-controller-manager \
  --address=0.0.0.0 \
  --cluster-cidr=10.200.0.0/16 \
  --cluster-name=kubernetes \
  --cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \
  --cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \
  --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \
  --leader-elect=true \
  --root-ca-file=/var/lib/kubernetes/ca.pem \
  --service-account-private-key-file=/var/lib/kubernetes/service-account-key.pem \
  --service-cluster-ip-range=10.32.0.0/24 \
  --use-service-account-credentials=true \
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

# Setup the kubernetes scheduler
- shh into the controller server
- Move the kube-scheduler.cubeconfig
```
sudo cp kube-scheduler.kubeconfig /var/lib/kubernetes
```

##### .yaml configuration file
- make sure you are putting these commands in the controler node(s)
```
cat << EOF | sudo tee /etc/kubernetes/config/kube-scheduler.yaml
apiVersion: kubescheduler.config.k8s.io/v1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: "/var/lib/kubernetes/kube-scheduler.kubeconfig"
leaderElection:
  leaderElect: true
EOF
```

##### Create the Scheduler systemd unit file
- now create the systemd unit file
```
cat <<EOF | sudo tee /etc/systemd/system/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-scheduler \
  --config=/etc/kubernetes/config/kube-scheduler.yaml \
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```


# Test & Troubleshoot the configurations
```
// Reload after any changes to the files weve made
sudo systemctl daemon-reload

// enable services to start on system startup
sudo systemctl enable kube-apiserver kube-controller-manager kube-scheduler

/////Start the services - Begin with etcd first if its not running////////
sudo systemctl start etcd
sudo systemctl start kube-apiserver kube-controller-manager kube-scheduler

// stop everything
sudo systemctl stop etcd kube-apiserver kube-controller-manager kube-scheduler

/// verify everything is up and working and setup properly
sudo systemctl status kube-apiserver kube-controller-manager kube-scheduler etcd

/// query the kubernetes control plane using kubectl
kubectl get componentstatuses --kubeconfig admin.kubeconfig
```

# use kubectl to check permissions
```
kubectl auth can-i create leases.coordination.k8s.io --kubeconfig admin.kubeconfig
kubectl auth can-i create leases.coordination.k8s.io --namespace kube-system --kubeconfig admin.kubeconfig

/// test kube controler managers access to the api
kubectl auth can-i create leases.coordination.k8s.io --namespace kube-system --as=system:kube-controller-manager --kubeconfig admin.kubeconfig
```
```
/// check all leases
kubectl get leases --all-namespaces --kubeconfig admin.kubeconfig
```
```
///Check lease aquisition
sudo journalctl -u kube-controller-manager | grep "successfully acquired lease"
```
- to trouble shoot any issues, use...
```
sudo journalctl -u kube-apiserver -f
sudo journalctl -u kube-controller-manager -f
sudo journalctl -u kube-scheduler -f
sudo journalctl -u etcd -f

// also check etcd
sudo systemctl status etcd

// check that etcd is listening properly:  
sudo ss -tuln | grep 2379
//tcp   LISTEN 0      4096       127.0.0.1:2379       0.0.0.0:*          
//tcp   LISTEN 0      4096   192.168.30.10:2379       0.0.0.0:*       
```

* Always be sure to reload and restart the service after making changes:
```
sudo systemctl daemon-reload
sudo systemctl restart etcd kube-apiserver.service kube-controller-manager.service kube-scheduler.service

sudo systemctl stop etcd kube-apiserver.service kube-controller-manager.service kube-scheduler.service

// check the status
sudo systemctl status etcd kube-apiserver.service kube-controller-manager.service kube-scheduler.service
```

- You can use
```
kubectl get componentstatuses --kubeconfig admin.kubeconfig
// Warning: v1 ComponentStatus is deprecated in v1.19+
// NAME                 STATUS    MESSAGE   ERROR
// scheduler            Healthy   ok        
// controller-manager   Healthy   ok        
// etcd-0               Healthy   ok  
// to check the health of the cluster but, 'get componentstatuses' is depricated so consider other methods to acess the heath status of the cluster
```


# Optional configurations examples : please refer to the Kubernetes docus
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