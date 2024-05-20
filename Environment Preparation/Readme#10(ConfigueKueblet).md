# Configure kubelet
 - Set variable and run these on all the worker nodes
 # Make sure everything is Lowercase *
```
 HOSTNAME=$(hostname)

 // move file into place
 sudo mv ${HOSTNAME}-key.pem ${HOSTNAME}.pem /var/lib/kubelet/

 // move to /var/lib/kueblet and rename to kubeconfig
 sudo mv ${HOSTNAME}.kubeconfig /var/lib/kubelet/kubeconfig

 // this is the local certificate authority the kubenetes services will use
 sudo mv ca.pem /var/lib/kubernetes/

// make the yaml configuration for the local kubelet
cat << EOF | sudo tee /var/lib/kubelet/kubelet-config.yaml
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
registerNode: true
failSwapOn: false
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: "/var/lib/kubernetes/ca.pem"
authorization:
  mode: Webhook
clusterDomain: "cluster.local"
clusterDNS:
  - "10.32.0.10"
runtimeRequestTimeout: "15m"
tlsCertFile: "/var/lib/kubelet/${HOSTNAME}.pem"
tlsPrivateKeyFile: "/var/lib/kubelet/${HOSTNAME}-key.pem"
containerRuntime: "remote"
containerRuntimeEndpoint: "unix:///var/run/containerd/containerd.sock"
EOF

// create the systemd unit file

cat << EOF | sudo tee /etc/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=containerd.service
Requires=containerd.service

[Service]
ExecStart=/usr/local/bin/kubelet \
  --config=/var/lib/kubelet/kubelet-config.yaml \
  --kubeconfig=/var/lib/kubelet/kubeconfig \
  --v=2 \
  --hostname-override=${HOSTNAME} \
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```
