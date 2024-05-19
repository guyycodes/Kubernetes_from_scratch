# Client Certificate Creation
- Make sure you in the directory with all your certificates

#### Generate the admin Client certificate
- Input 
```
{

cat > admin-csr.json << EOF
{
  "CN": "admin",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "McAllen",
      "O": "system:masters",
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
  admin-csr.json | cfssljson -bare admin

}
```

#### Explination of the warning:
```
The warning message you encountered is related to the generation of a certificate that lacks the "hosts" field, also known as the Subject Alternative Name (SAN) field. This field is crucial for defining the entities (domain names, IP addresses) for which the certificate is valid. When you're building a hosting service where applications can live, clients (browsers, other services) will connect to these applications via domain names or IP addresses. The certificate presented by your service during the TLS handshake must be valid for these domain names or IP addresses; otherwise, clients will raise security warnings or refuse to connect.

The CA/Browser Forum's Baseline Requirements specify that all publicly-trusted certificates must contain a SAN field that specifies the authorized domain names or IP addresses that the certificate covers. Without this field, the certificate is considered invalid for securing web traffic.

In the context of Kubernetes and other non-browser clients, while the requirement for the "hosts" field may not be as strictly enforced by all clients, it's still essential for ensuring your services are trusted and can establish secure connections without issues.

How to Include the "hosts" Field in Your Certificates
When generating certificates, especially for services that will be exposed to the web or accessed by clients that verify certificate validity, you should include the "hosts" field in your Certificate Signing Request (CSR) configuration. Here's an example of how to include the "hosts" field in a CSR JSON configuration:

{
  "CN": "my-service.example.com",
  "hosts": [
    "my-service.example.com",
    "www.my-service.example.com",
    "192.0.2.1"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "McAllen",
      "O": "system:masters",
      "OU": "iOTHost",
      "ST": "South Texas Region"
    }
  ]
}
In this example, the "hosts" field lists the primary domain (my-service.example.com), an additional subdomain (www.my-service.example.com), and an IP address (192.0.2.1). Any of these can be used to access the service, and the certificate will be considered valid.

* You will need certificates for each users ip/domain who hosts a application on the cluster, but these certificates can be automated an created by a 3rd party service to streamline the process, unless you want full control. 

Programmatic Certificate Generation
API for Certificate Requests: Implement an API or interface where users can request a certificate for their domain. This could be part of your service's dashboard or a standalone API endpoint.

Automate CSR Generation: Once a user submits a request for a domain, programmatically generate a Certificate Signing Request (CSR) including the specified domain and any other information (like IP addresses) in the "hosts" field.

Sign with Your CA: Use your Certificate Authority (CA) to sign the CSR and generate a certificate. If you're acting as your own CA, this process can be fully automated. If you're using an external CA (especially for publicly trusted certificates), you may need to automate interactions with the CA's API.

Distribute Certificates and Keys: After generating the certificate, securely distribute the certificate and private key to the user's application or service within your cluster. Ensure the private key is handled securely and is not exposed.

Renewal and Revocation: Implement mechanisms for renewing certificates before they expire and revoking them if they're no longer needed or if their security is compromised.

Considerations for Publicly Accessible Services
For services that will be exposed to the Internet, you might consider using a third-party CA that issues publicly trusted certificates, such as Let's Encrypt, which can automate much of the process. For internal services or if you prefer to maintain full control, you can continue to use your own CA, keeping in mind that certificates signed by your CA will need to be trusted explicitly by clients outside your organization.

```
# Client Certificaes for Kublet
#### Set the certificates for the worker nodes
- Make a variable in the terminal 
- assign the hostname from the first worker node to this first variable
- assign the ip address from this first worker to the second variable
* Perform this step for all worker nodes (in my case it looked like this)

# * KUBERNETES REQUIRES LOWERCASE HOSTNAMES, ALL THINGS LOWERCASE!! * #

```
 WORKER0_HOST=levelup2   
 WORKER0_IP=192.168.30.11

// if you have worker nodes add them like this
 WORKER1_HOST=raspberrypHTTPS
 WORKER1_IP=192.168.30.245

 WORKER2_HOST=raspiHTTPS1
 WORKER2_IP=192.168.30.251
 
 //you can test your env vars on terminal like this
 echo $WORKER0_HOST
 ```

- after defining the variables input this command to generate certificates for the kublets
- Only generate the certificate for as many worker nodes as you need (Ive included several exta examples)
```
{
cat > ${WORKER0_HOST}-csr.json << EOF
{
  "CN": "system:node:${WORKER0_HOST}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "McAllen",
      "O": "system:nodes",
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
  -hostname=${WORKER0_IP},${WORKER0_HOST} \
  -profile=kubernetes \
  ${WORKER0_HOST}-csr.json | cfssljson -bare ${WORKER0_HOST}

cat > ${WORKER1_HOST}-csr.json << EOF
{
  "CN": "system:node:${WORKER1_HOST}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "McAllen",
      "O": "system:nodes",
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
  -hostname=${WORKER1_IP},${WORKER1_HOST} \
  -profile=kubernetes \
  ${WORKER1_HOST}-csr.json | cfssljson -bare ${WORKER1_HOST}

cat > ${WORKER2_HOST}-csr.json << EOF
{
  "CN": "system:node:${WORKER2_HOST}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "McAllen",
      "O": "system:nodes",
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
  -hostname=${WORKER2_IP},${WORKER2_HOST} \
  -profile=kubernetes \
  ${WORKER2_HOST}-csr.json | cfssljson -bare ${WORKER2_HOST}
}
```

# Certificate generation for the controller manager
#### Let look at our architecture and see the controller manager
- input this command
```
{

cat > kube-controller-manager-csr.json << EOF
{
  "CN": "system:kube-controller-manager",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "McAllen",
      "O": "system:kube-controller-manager",
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
  kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager

}
```

# Generate kube-proxy certificate
- input this command
```
{

cat > kube-proxy-csr.json << EOF
{
  "CN": "system:kube-proxy",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "McAllen",
      "O": "system:nodes",
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
  kube-proxy-csr.json | cfssljson -bare kube-proxy

}
```

# Generate certificate for kube-scheduler
- input this command
```
{

cat > kube-scheduler-csr.json << EOF
{
  "CN": "system:kube-scheduler",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "McAllen",
      "O": "system:kube-scheduler",
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
  kube-scheduler-csr.json | cfssljson -bare kube-scheduler

}
```