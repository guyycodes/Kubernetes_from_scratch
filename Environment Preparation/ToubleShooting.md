# in case you need to regenerate certificates:

* Impact on Other Certificates
In a typical Kubernetes setup, changing the API server's certificate to include a new IP address does not necessarily require regenerating all other certificates in the cluster. Most components trust the API server's certificate based on the CA that signed it, rather than the certificate itself. As long as the CA remains the same, and the components are configured to trust certificates signed by that CA, only the API server's certificate needs to be updated in this scenario.

- However, if the CA certificate (ca.pem) itself changes, then you would need to update all components that rely on it to trust the new CA.

- To copy all the necessary files for the gencert command into the kubeCertificateAuthority-redo-certificates directory, you need to identify which files are directly involved in the certificate generation process you've outlined. Based on the command snippet you provided, the necessary files are:

* ca.pem: The CA certificate.
* ca-key.pem: The CA's private key.
* ca-config.json: The CA configuration file.
* kubernetes-csr.json: The CSR configuration for generating the Kubernetes certificate.

```
cp ca.pem ca-key.pem ca-config.json kubernetes-csr.json ./kubeCertificateAuthority-redo-certificates/
```
* After copying these files, you can navigate to the kubeCertificateAuthority-redo-certificates directory and run your cfssl gencert command there. Make sure that your CERT_HOSTNAME environment variable is set correctly before running the command. If you haven't done so already, you can set it like this:
```
export CERT_HOSTNAME="10.31.0.1,192.168.30.10,levelup1,192.168.20.251,raspberrypiLB,127.0.0.1,localhost,kubernetes.default"
```
# Updateing the certificate on the server
- When updating critical components like the Kubernetes API server's TLS certificates, it's essential to follow a careful and orderly process to minimize downtime and potential issues. Here's a recommended sequence of steps:

* 1. Backup Existing Certificates
Always start with backing up the existing certificates. This ensures that you can revert to the original state if anything goes wrong during the update process.
```
mv kubernetes.pem kubernetes.pem.backup
mv kubernetes-key.pem kubernetes-key.pem.backup
```
2. Stop the API Server (Optional but Recommended)
Stopping the API server while updating the certificates can prevent half-configured states and other potential issues. However, this will cause downtime, so you should plan this step according to your downtime window or maintenance schedule.
```
sudo systemctl stop kube-apiserver
```
3. Copy the New Certificates
After stopping the API server and backing up the old certificates, copy the new certificates to the desired location. If you've already copied them as per previous instructions but haven't moved or renamed them yet, you can skip this step.
```
// Copy the New Certificates
scp kubernetes.pem kubernetes-key.pem levelup@192.168.30.10:~/

// ensure proper ownership
sudo chown root:root kubernetes.pem kubernetes-key.pem
sudo chmod 600 kubernetes-key.pem
sudo chmod 644 kubernetes.pem

// restart api server
sudo systemctl restart kube-apiserver
// check api server
sudo systemctl status kube-apiserver
```

```
// gracefull shutdown, run this before turning everything off
kubectl drain levelup1 --ignore-daemonsets --delete-emptydir-data 
```

```
// use this command to enter your deburrer node
kubectl exec -it $(kubectl get pods -l app=debugger -o jsonpath='{.items[0].metadata.name}') -- /bin/sh
```

```
// use this command to check the subject alternative names
openssl x509 -in /var/lib/kubelet/levelup2.pem -noout -text | grep -A 1 "Subject Alternative Name"
            X509v3 Subject Alternative Name: 
                DNS:levelup2, IP Address:192.168.30.11
```
```
// create a container and deploy it, and debug fom inside the pod
- at this path we have done that: /Users/guymorganb/Desktop/GitHub_Repos/DockerFiles/my-custom-netshoot.Dockerfile
```