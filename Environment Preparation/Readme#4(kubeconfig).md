# Create the kube config files and distribute them

```
A kube config file is a configuration file that contains the information we need to connect to and interact with one or more kubernetes cluster
The cube config allows you to connect to multiple kubernetes clusters, kubectl is used to generate the kubeconfigs
```

- example use of kubectl command:

```
kubectl config set-cluster
```

- to setup the configuration for the location of the cluster
- example use of kubectl command

```
kubectl config set-credentials
```

- to set the username and client certificate that will be used to authenticate
- example use of kubectl command

```
kubectl config set-context default
kubectl config use-context default
```

- to configure and use the default context that we set

#### By the end our certificates will cover:

- kublet(one for each worker node)
- kube proxy
- kube controller manager
- kube scheduler
- Admin

##### Generate kube configs for kublets

- Set an env variable with the ip address of the device that is the load balancer
- run a for loop over the worker nodes

```
KUBERNETES_ADDRESS=192.168.20.251

for instance in <woker 1 hostname> <worker 2 hostname> <worker 3 hostname>; do
```

- above is the example loop, below is the actual loop if you only have one worker node you may not need to make a loop
- just use what is relevant to your use case

```
for instance in levelup2 raspberrypHTTPS raspiHTTPS1; do
    kubectl config set-cluster iOTHost \
      --certificate-authority=ca.pem \
      --embed-certs=true \
      --server=https://${KUBERNETES_ADDRESS}:6443 \
      --kubeconfig=${instance}.kubeconfig

    kubectl config set-credentials system:node:${instance} \
      --client-certificate=${instance}.pem \
      --client-key=${instance}-key.pem \
      --embed-certs=true \
      --kubeconfig=${instance}.kubeconfig

    kubectl config set-context default \
      --cluster=iOTHost \
      --user=system:node:${instance} \
      --kubeconfig=${instance}.kubeconfig

    kubectl config use-context default --kubeconfig=${instance}.kubeconfig
  done
```

##### Now generate the kube configs for kube proxy

```
{
    kubectl config set-cluster iOTHost \
      --certificate-authority=ca.pem \
      --embed-certs=true \
      --server=https://${KUBERNETES_ADDRESS}:6443 \
      --kubeconfig=kube-proxy.kubeconfig

    kubectl config set-credentials system:kube-proxy \
      --client-certificate=kube-proxy.pem \
      --client-key=kube-proxy-key.pem \
      --embed-certs=true \
      --kubeconfig=kube-proxy.kubeconfig

    kubectl config set-context default \
      --cluster=iOTHost \
      --user=system:kube-proxy \
      --kubeconfig=kube-proxy.kubeconfig

    kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
}
```

##### Generate Kube controler manager kube config

```
{
    kubectl config set-cluster iOTHost \
      --certificate-authority=ca.pem \
      --embed-certs=true \
      --server=https://127.0.0.1:6443 \
      --kubeconfig=kube-controller-manager.kubeconfig

    kubectl config set-credentials system:kube-controller-manager \
      --client-certificate=kube-controller-manager.pem \
      --client-key=kube-controller-manager-key.pem \
      --embed-certs=true \
      --kubeconfig=kube-controller-manager.kubeconfig

    kubectl config set-context default \
      --cluster=iOTHost \
      --user=system:kube-controller-manager \
      --kubeconfig=kube-controller-manager.kubeconfig

    kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig
}
```

##### Generate Kube scheduler kube config

```
{
    kubectl config set-cluster iOTHost \
      --certificate-authority=ca.pem \
      --embed-certs=true \
      --server=https://127.0.0.1:6443 \
      --kubeconfig=kube-scheduler.kubeconfig

    kubectl config set-credentials system:kube-scheduler \
      --client-certificate=kube-scheduler.pem \
      --client-key=kube-scheduler-key.pem \
      --embed-certs=true \
      --kubeconfig=kube-scheduler.kubeconfig

    kubectl config set-context default \
      --cluster=iOTHost \
      --user=system:kube-scheduler \
      --kubeconfig=kube-scheduler.kubeconfig

    kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig
}
```

##### Generate Kube config for admin user

```
{
    kubectl config set-cluster iOTHost \
      --certificate-authority=ca.pem \
      --embed-certs=true \
      --server=https://127.0.0.1:6443 \
      --kubeconfig=admin.kubeconfig

    kubectl config set-credentials admin \
      --client-certificate=admin.pem \
      --client-key=admin-key.pem \
      --embed-certs=true \
      --kubeconfig=admin.kubeconfig

    kubectl config set-context default \
      --cluster=iOTHost \
      --user=admin \
      --kubeconfig=admin.kubeconfig

    kubectl config use-context default --kubeconfig=admin.kubeconfig
}
```

##### Distribute Kubeconfigs to the worker nodes

- use scp command to disperse kubeconfigs - again, use what is relevant to your setup ive included extra examples

```
scp levelup2.kubeconfig kube-proxy.kubeconfig levelup@192.168.30.11:~/

scp raspberrypHTTPS.kubeconfig kube-proxy.kubeconfig guymorganb@192.168.30.245:~/

scp raspiHTTPS1.kubeconfig kube-proxy.kubeconfig guymorganb@192.168.30.251:~/
```
##### Distribute Kubeconfigs to the controler node(s)

- use scp command to disperse kubeconfigs

```
scp admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig levelup@192.168.30.10:~/
```

# Generate Data encryption config

- We will generate a encryption key and put it into a configuration file, we will then copy that file to our control servers
- Kubernetes supports the ability to encrypt secret data at rest
- Set an random env variable
```
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

echo $ENCRYPTION_KEY
ZXs62IGX4xj3/tumhUEyjDJ66pfI92anITXXYd8yf+I=
```
```
cat > encryption-config.yaml << EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF
```
- upload this to the controler node(s)
```
scp encryption-config.yaml levelup@192.168.30.10:~/
```
