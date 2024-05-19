# Generate the server certificate for the kubernetes API
- ensure you cd into the directory where all the certificates have been generated so far

#### Setting variables for the hostnames that will sign the certificates
- We need to make sure to sign this certificate with al the Hostnames and IP's that we might use to access the kubernetes api this certificate will provide a secure HTTPS connection to the kubernetes API
```
 CERT_HOSTNAME=10.31.0.1,10.32.0.1,192.168.30.10,levelup1,192.168.20.251,raspberrypiLB,127.0.0.1,localhost,kubernetes.default
```
- Perform for all controllers
- 10.32.0.1: is an internal ip that some services inside kubernetes might end up using
- 192.168.30.10: Private ip of the controler node(s) 
- levelup1: Hostname of the controler node(s)

- Perform for all load balancer(s)
- 192.168.20.251: private ip of load balancer
- raspberrypiLB: hostname of load balancer
- 127.0.0.1: for localhost, some kubernetes service will use this
- localhost: hostname for localhost is 'localhost'
- kubernetes.default: similar to 10.32.0.1, is an internal ip that might be used to acess the API.

#### After creating the variable, run the command below
```
{

cat > kubernetes-csr.json << EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "McAllen",
      "O": "Kubernetes",
      "OU": "iOTHost",
      "ST": "South Texas Region"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=${CERT_HOSTNAME} \
  -profile=kubernetes \
  kubernetes-csr.json | cfssljson -bare kubernetes

}
```

# Generating the Service Account key-pair
- cd into the directory where all the certificates are stored
```
In Kubernetes, a service account is a type of user account that is intended for processes, which run in pods, to interact with the Kubernetes API. Unlike regular user accounts that might be used by human operators of the cluster, service accounts are meant to provide an identity for applications running within your pods.

Here are some key points about service accounts in Kubernetes:

- Identity for Processes: Service accounts provide an identity for processes that run in a pod. When a process inside a pod accesses the Kubernetes API, it can authenticate itself with the API server using the credentials of a service account.
Automated API Authentication: Service accounts help in automating the process of authentication to the Kubernetes API, which is crucial for applications that are dynamically managed by Kubernetes. Each service account is associated with a set of credentials automatically, which can be accessed through the Kubernetes secret store.

- Scoped Permissions: You can define permissions for a service account using role-based access control (RBAC) policies. This allows you to specify exactly what actions a service account can perform on the Kubernetes resources. This is useful for implementing the principle of least privilege, where an application has only the permissions it needs to operate.
Default Accounts: Kubernetes automatically creates a default service account in each namespace. When a pod doesn't explicitly specify a service account, it is assigned this default service account.
Use in CI/CD Pipelines: In the context of CI/CD pipelines, service accounts are often used to give your CI/CD tools the necessary permissions to deploy and manage applications in your Kubernetes cluster.
```
-input this command: 
```
{

cat > service-account-csr.json <<EOF
{
  "CN": "service-accounts",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "McAllen",
      "O": "Kubernetes",
      "OU": "iOTHost",
      "ST": "South Texas Region"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  service-account-csr.json | cfssljson -bare service-account

}
```

# Distribute the certificates to the nodes
- we will use the 'scp' command to copy file betweeen machines (secure copy protocol) 
```
scp
```
- Beginin with the worker node(s) 
- Ive included extra examples so you have them as a reference, only use what applies to you
```
scp ca.pem levelup2-key.pem levelup2.pem levelup@192.168.30.11:~/
scp ca.pem raspberrypHTTPS-key.pem raspberrypHTTPS.pem guymorganb@192.168.30.245:~/
scp ca.pem raspiHTTPS1-key.pem raspiHTTPS1.pem guymorganb@192.168.30.251:~/
```

- Now send the certificates to the controll node(s)
```
scp ca.pem ca-key.pem ca-key.pem kubernetes-key.pem kubernetes.pem service-account-key.pem service-account.pem levelup@192.168.30.10:~/
```
