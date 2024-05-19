# etc
#### etcd: is a distributed key:value store that provides a reliable way to store data across a cluster of machines
- etcd provides a way to store data across a distributed cluster of machines and makes sure the data is syncronized across all machines
- The data needs to be stored an reliably syncronozed across all controller nodes in the cluster includes all of those controler nodes

##### Steps (do all commands on all controler servers)
- log into the control server(s)
- download the etcd binaries and extract the archive
```
wget -q --show-progress --https-only --timestamping \
    https://github.com/coreos/etcd/releases/download/v3.3.15/etcd-v3.3.15-linux-amd64.tar.gz

// extract
tar -xvf etcd-v3.3.15-linux-amd64.tar.gz

// move the executable extracted
sudo mv etcd-v3.3.15-linux-amd64/etcd* /usr/local/bin/
```
- create the directories needed to run etcd
```
sudo mkdir -p /etc/etcd /var/lib/etcd
```
- move the certificates into the correct directories
```
sudo cp ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/
```

##### Now well create the systemd unit file(these commands need to be run on all controllers) so if you add a server itll need this specific to that server

- set env variables (THE ETCD_NAME must be unique, it is the unique name of the etcd node int the cluster)
- set the internal ip (this is the private ip)
- set the intial_cluster, a list of all the servers in the etcd cluster, the list must be accurate to use etcd to communicate
- create a systemd unit file that creates the linux service for etcd
```
ETCD_NAME=levelup1
INTERNAL_IP=192.168.30.10
INITIAL_CLUSTER=levelup1=https://192.168.30.10:2380,<name of other server=ip:port>

// create the systemd unit file
cat << EOF | sudo tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd/kubernetes.pem \\
  --key-file=/etc/etcd/kubernetes-key.pem \\
  --peer-cert-file=/etc/etcd/kubernetes.pem \\
  --peer-key-file=/etc/etcd/kubernetes-key.pem \\
  --trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster ${INITIAL_CLUSTER}  \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Type=notify
Restart=on-failurď
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```
- restart systemd so it seees the changes. 
- enable etcd
- start etcd
```
sudo systemctl daemon-reload
sudo systemctl enable etcd
sudo systemctl start etcd
// check etcd
sudo systemctl status etcd

// check the cluster formed proper
sudo ETCDCTL_API=3 etcdctl member list \
    --endpoints=https://127.0.0.1:2379 \
    --cacert=/etc/etcd/ca.pem \
    --cert=/etc/etcd/kubernetes.pem \
    --key=/etc/etcd/kubernetes-key.pem

```
# Install Kubernetes
- The kubernetes control plane is a set of services that control the kubernetes cluster
- Control plane components make global decisions abut the cluster, like scheduling, and detect and respond to cluster events, when a replication controllers replica feild is unsatisfied
- Kube api is the interface we use to interact with the cluster
- etcd handles data syncronization and is a data store across all nodes
- kube scheduler handles spinning up pods on nodes that are avaliabel
- kube controler manager
- Cloud controller manager, handles interaction and integration with underlying cloud providers
##### Install the Kubernetes Control plane binaries on the Kubernetes Controller(s)
- Login to the control server (perform these commands for all servers)
- make the directory
- download the binaries
- Add an executable permission to the executables
- move the files into the correct location
```
sudo mkdir -p /etc/kubernetes/config
wget -q --show-progress --https-only --timestamping \
    "https://storage.googleapis.com/kubernetes-release/release/v1.30.0/bin/linux/amd64/kube-apiserver" \
    "https://storage.googleapis.com/kubernetes-release/release/v1.30.0/bin/linux/amd64/kube-controller-manager" \
    "https://storage.googleapis.com/kubernetes-release/release/v1.30.0/bin/linux/amd64/kube-scheduler" \
    "https://storage.googleapis.com/kubernetes-release/release/v1.30.0/bin/linux/amd64/kubectl" \
    "https://storage.googleapis.com/kubernetes-release/release/v1.11.0/bin/linux/amd64/cloud-controller-manager"

chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl cloud-controller-manager

sudo mv kube-apiserver kube-controller-manager kube-scheduler kubectl cloud-controller-manager /usr/local/bin/
```
