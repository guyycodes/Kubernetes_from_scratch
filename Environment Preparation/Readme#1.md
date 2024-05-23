# Provisioning Servers

For this course, we will need a total of **3 servers**:

- 1 Kubernetes controller
- 1 Kubernetes worker nodes
- 1 Kubernetes API load balancer
- Homebrew if your using Mac

The operating system we will be using is **Ubuntu 20.04 LTS**.

### In my setup Ill have a home network I built behing my ISP modem: But this can be done in the cloud
#### Subnet 30 (Controller)
- levelup1: as the Controller ip: 192.168.30.10 hostname: levelup1

#### Subnet 30 (Worker)
- levelup2 as a WORKER0: 192.168.30.11 hostname: levelup2

#### Subnet 20(Load Balancer)
- raspberrypiLB as a LoabBalancer: 192.168.20.251 hostname: raspberrypiLB

## Client Tools & End-to-end encryption

#### These tool belong on the local machine: the machine used to connect to the Kubernetes Cluster

- kubectl: command-line tool used for interacting with Kubernetes clusters. It allows you to manage and control various aspects of your Kubernetes environment.

- CFSSL: an open-source toolkit for TLS/SSL certificate management. It is used by CloudFlare internally for bundling TLS/SSL certificate chains and managing their internal Certificate Authority infrastructure

 #### kubectl for mac
- brew install kubectl
- kubectl version --client

 #### cfssl steps for Mac
   - curl -o cfssl https://pkg.cfssl.org/R1.2/cfssl_darwin-amd64
   - url -o cfssljson https://pkg.cfssl.org/R1.2/cfssljson_darwin-amd64
   - ls -l cfssl cfssljson

   * chmod +x cfssl cfssljson
   * sudo mv cfssl cfssljson /usr/local/bin/
   * Finally, verify that the binaries are available in the /usr/local/bin/ directory by running: ls -l /usr/local/bin/cfssl /usr/local/bin/cfssljson, you should see this permission next to the binaries 
    - or use: 
   * brew instal cfssl

# Certificate Authority 

#### A certificate Authority (CA) is used to create several certificates

- Cerificates are used to confirm authenticity
- A CA provides a way to ensure the certificate is valid, a CA can be used to authenticate any certificate issued using that CA.
- Different parts of the cluster will validate certificates

#### Client Certificates
- These provide authentication for various users: admin, kube-controller manager, kube proxy, kube-scheduler and the kublets

#### Kubernetes API server certificate
- The TLS certificate for the kubernetes API

#### Service account Key Pair
- Kubernetes uses a certificate to sign account tokens, which is what this certificate is for
    
## Certificate Authority steps:
#### On local machine: 
- ``` mkdir kubeCertificateAuthority ``` ... or name it whatever youd like
- ``` cd kubeCertificateAuthority``` 
* We will now create a certificate authority
``` 
{
cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
          "usages": ["signing", "key encipherment", "server auth", "client auth"],
          "expiry": "8760h"
      }
    }
  }
}
EOF

cat > ca-csr.json <<EOF
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "McAllen",
      "O": "Kubernetes",
      "OU": "CA",
      "ST": "South Texas Region"
    }
  ]
}
EOF

cfssl gencert -initca ca-csr.json | cfssljson -bare ca

} 
 ```

- Execute those commands inside your newly created directory
- ls should yeild: 
```
ca-config.json ca-csr.json    ca-key.pem     ca.csr         ca.pem
```
- ca-key.pem is the private certificate
- ca.pem is the public certificate (various components will need this to authenticate we will be placing it many places)